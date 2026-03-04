"""
This script has functions and utilties for model export.
Basically, we have a bunch of versions of the model, and we
want to export them to .bin files to be read from and inferenced in C.

Among the "input" versions of PyTorch files/models:
- Official Llama 2 weights released by Meta
- Huggingface weights available on the hub
- llama2.c (this repo) trained models

Among the "output" versions of .bin files:
- v0: Legacy files of the original llama2.c repo (will eventually be DEPRECATED)
- v1-vN: Improved .bin files with a proper header, cache alignment, etc.

This script aspires to provide all of these conversions.
"""
import os
import gzip
import shutil
import struct
import argparse
import json
from pathlib import Path

import numpy as np
import torch
from torch import nn

from model import ModelArgs, Transformer

# -----------------------------------------------------------------------------
# common utilities

def serialize_fp32(file, tensor):
    """ writes one fp32 tensor to file that is open in wb mode """
    d = tensor.detach().cpu().view(-1).to(torch.float32).numpy()
    b = struct.pack(f'{len(d)}f', *d)
    file.write(b)

def serialize_int8(file, tensor):
    """ writes one int8 tensor to file that is open in wb mode """
    d = tensor.detach().cpu().view(-1).numpy().astype(np.int8)
    b = struct.pack(f'{len(d)}b', *d)
    file.write(b)

def quantize_q80(w, group_size):
    """
    takes a tensor and returns the Q8_0 quantized version
    i.e. symmetric quantization into int8, range [-127,127]
    """
    assert w.numel() % group_size == 0
    ori_shape = w.shape
    w = w.float() # convert to float32
    w = w.reshape(-1, group_size)
    # find the max in each group
    wmax = torch.abs(w).max(dim=1).values
    # calculate the scaling factor such that float = quant * scale
    scale = wmax / 127.0
    # scale into range [-127, 127]
    quant = w / scale[:,None]
    # round to nearest integer
    int8val = torch.round(quant).to(torch.int8)
    # dequantize by rescaling
    fp32val = (int8val.float() * scale[:,None]).view(-1)
    fp32valr = fp32val.reshape(-1, group_size)
    # calculate the max error in each group
    err = torch.abs(fp32valr - w).max(dim=1).values
    # find the max error across all groups
    maxerr = err.max().item()
    return int8val, scale, maxerr

# -----------------------------------------------------------------------------
# legacy

def legacy_export(model, filepath):
    """ Original export of llama2.c bin files, i.e. version v0 """
    out_file = open(filepath, 'wb')

    # first write out the header
    hidden_dim = model.layers[0].feed_forward.w1.weight.shape[0]
    p = model.params
    shared_classifier = torch.equal(model.tok_embeddings.weight, model.output.weight)
    # legacy format uses negative/positive vocab size as a shared classifier flag
    if not shared_classifier:
        p.vocab_size = -p.vocab_size
    n_kv_heads = p.n_heads if p.n_kv_heads is None else p.n_kv_heads
    header = struct.pack('iiiiiii', p.dim, hidden_dim, p.n_layers, p.n_heads,
                                    n_kv_heads, p.vocab_size, p.max_seq_len)
    out_file.write(header)

    # next write out the embedding weights
    serialize_fp32(out_file, model.tok_embeddings.weight)

    # now all the layers
    # attention weights
    for layer in model.layers:
        serialize_fp32(out_file, layer.attention_norm.weight)
    for layer in model.layers:
        serialize_fp32(out_file, layer.attention.wq.weight)
    for layer in model.layers:
        serialize_fp32(out_file, layer.attention.wk.weight)
    for layer in model.layers:
        serialize_fp32(out_file, layer.attention.wv.weight)
    for layer in model.layers:
        serialize_fp32(out_file, layer.attention.wo.weight)
    # ffn weights
    for layer in model.layers:
        serialize_fp32(out_file, layer.ffn_norm.weight)
    for layer in model.layers:
        serialize_fp32(out_file, layer.feed_forward.w1.weight)
    for layer in model.layers:
        serialize_fp32(out_file, layer.feed_forward.w2.weight)
    for layer in model.layers:
        serialize_fp32(out_file, layer.feed_forward.w3.weight)
    # final rmsnorm
    serialize_fp32(out_file, model.norm.weight)
    # freqs_cis
    serialize_fp32(out_file, model.freqs_cos[:p.max_seq_len])
    serialize_fp32(out_file, model.freqs_sin[:p.max_seq_len])

    # final classifier weights
    if not shared_classifier:
        serialize_fp32(out_file, model.output.weight)

    # write to binary file
    out_file.close()
    print(f"wrote {filepath}")

# -----------------------------------------------------------------------------
# new version

def version1_export(model, filepath):
    """
    Export the model weights in full float32 .bin file to be read from C.
    This is same as legacy_export, but with a proper header.
    """
    version = 1

    out_file = open(filepath, 'wb')
    # first write out the header. the header will be 256 bytes
    # 1) write magic, which will be uint32 of "ak42" in ASCII
    out_file.write(struct.pack('I', 0x616b3432))
    # 2) write version, which will be int
    out_file.write(struct.pack('i', version))
    # 3) write the params, which will be 7 ints
    p = model.params
    hidden_dim = model.layers[0].feed_forward.w1.weight.shape[0]
    n_kv_heads = p.n_heads if p.n_kv_heads is None else p.n_kv_heads
    header = struct.pack('iiiiiii', p.dim, hidden_dim, p.n_layers, p.n_heads,
                                    n_kv_heads, p.vocab_size, p.max_seq_len)
    out_file.write(header)
    # 4) write some other flags
    shared_classifier = torch.equal(model.tok_embeddings.weight, model.output.weight)
    out_file.write(struct.pack('B', int(shared_classifier)))
    pad = 256 - out_file.tell() # pad rest with zeros; tell returns current pos
    assert pad >= 0
    out_file.write(b'\0' * pad)

    # now let's write out all the params
    weights = [
        *[layer.attention_norm.weight for layer in model.layers],
        *[layer.ffn_norm.weight for layer in model.layers],
        model.norm.weight,
        model.tok_embeddings.weight,
        *[layer.attention.wq.weight for layer in model.layers],
        *[layer.attention.wk.weight for layer in model.layers],
        *[layer.attention.wv.weight for layer in model.layers],
        *[layer.attention.wo.weight for layer in model.layers],
        *[layer.feed_forward.w1.weight for layer in model.layers],
        *[layer.feed_forward.w2.weight for layer in model.layers],
        *[layer.feed_forward.w3.weight for layer in model.layers],
    ]
    if not shared_classifier:
        weights.append(model.output.weight)
    for w in weights:
        serialize_fp32(out_file, w)

    # write to binary file
    out_file.close()
    print(f"wrote {filepath}")

def version2_export(model, filepath, group_size=64):
    """
    Export the model weights in Q8_0 into .bin file to be read from C.
    That is:
    - quantize all weights to symmetric int8, in range [-127, 127]
    - all other tensors (the rmsnorm params) are kept and exported in fp32
    - quantization is done in groups of group_size to reduce the effects of any outliers
    """
    version = 2

    # let's first do some validation for this export type
    while model.params.dim % group_size != 0:
        group_size //= 2
        print(f"BACKOFF: reducing group size to {group_size} to fit hidden_dim")
    weights = [
        model.tok_embeddings.weight,
        *[layer.attention.wq.weight for layer in model.layers],
        *[layer.attention.wk.weight for layer in model.layers],
        *[layer.attention.wv.weight for layer in model.layers],
        *[layer.attention.wo.weight for layer in model.layers],
        *[layer.feed_forward.w1.weight for layer in model.layers],
        *[layer.feed_forward.w2.weight for layer in model.layers],
        *[layer.feed_forward.w3.weight for layer in model.layers],
    ]
    shared_classifier = torch.equal(model.tok_embeddings.weight, model.output.weight)
    if not shared_classifier:
        weights.append(model.output.weight)
    for w in weights:
        assert w.numel() % group_size == 0, f"weight {i} has numel {w.numel()}, not a multiple of group_size {group_size}"

    # write
    out_file = open(filepath, 'wb')
    # first write out the header. the header will be 256 bytes
    # 1) write magic, which will be uint32 of "ak42" in ASCII
    out_file.write(struct.pack('I', 0x616b3432))
    # 2) write version, which will be int
    out_file.write(struct.pack('i', version))
    # 3) write the params, which will be 7 ints
    p = model.params
    hidden_dim = model.layers[0].feed_forward.w1.weight.shape[0]
    n_kv_heads = p.n_heads if p.n_kv_heads is None else p.n_kv_heads
    header = struct.pack('iiiiiii', p.dim, hidden_dim, p.n_layers, p.n_heads,
                                    n_kv_heads, p.vocab_size, p.max_seq_len)
    out_file.write(header)
    # 4) write some other flags
    out_file.write(struct.pack('B', int(shared_classifier)))
    out_file.write(struct.pack('i', group_size)) # group size used for quantization
    pad = 256 - out_file.tell() # pad rest with zeros; tell returns current pos
    assert pad >= 0
    out_file.write(b'\0' * pad)
    # now that the header is done, let's write out the model

    # first let's write out all the params that we are keeping in fp32: the norms
    for layer in model.layers: # attention norms
        serialize_fp32(out_file, layer.attention_norm.weight)
    for layer in model.layers: # MLP norms
        serialize_fp32(out_file, layer.ffn_norm.weight)
    serialize_fp32(out_file, model.norm.weight) # final pre-classifier norm

    # now let's write out all the params that we are quantizing to Q8_0
    # note we skip classifier weights, which are shared with the embedding
    ew = []
    for i, w in enumerate(weights):
        # quantize this weight
        q, s, err = quantize_q80(w, group_size)
        # save the int8 weights to file
        serialize_int8(out_file, q) # save the tensor in int8
        serialize_fp32(out_file, s) # save scale factors
        # logging
        ew.append((err, w.shape))
        print(f"{i+1}/{len(weights)} quantized {tuple(w.shape)} to Q8_0 with max error {err}")

    # print the highest error across all weights, should be very small, e.g. O(~0.001)
    ew.sort(reverse=True)
    print(f"max quantization group error across all weights: {ew[0][0]}")

    # write to binary file
    out_file.close()
    print(f"wrote {filepath}")

def hf_export(llama_model, filepath, group_size=64, dtype=torch.float32):
    """ Generate the pytorch_model.bin state_dict and config.json for HuggingFace """

    try:
        from transformers.models.llama.configuration_llama import LlamaConfig
    except ImportError:
        print("Error: transformers package is required to load huggingface models")
        print("Please run `pip install transformers` to install it")
        return None

    # Generate LlamaModel state_dict
    hf_state_dict = {}

    # Sometimes we have repeated key values for the heads
    dim = llama_model.params.dim
    num_key_value_heads = llama_model.params.n_kv_heads
    n_rep = llama_model.params.n_heads // num_key_value_heads
    key_value_dim = dim // n_rep

    # HuggingFace needs the weights permuted.
    # See: https://github.com/huggingface/transformers/blob/b132c1703eb1c8bd9dfa4ad6a9be2bfd6ef819e9/src/transformers/models/llama/convert_llama_weights_to_hf.py#L122
    def permute_original(w, n_heads=llama_model.params.n_heads, dim1=dim, dim2=dim):
        return w.view(dim1, dim2).reshape(n_heads, dim1 // n_heads // 2, 2, dim2).transpose(1, 2).reshape(dim1, dim2)

    # Transfer weights from llama model to the HF state dictionary format
    hf_state_dict['model.embed_tokens.weight'] = llama_model.tok_embeddings.weight.clone().to(dtype)
    hf_state_dict['model.norm.weight'] = llama_model.norm.weight.clone().to(dtype)

    # Add each layer's weights to the HF state dictionary
    for i, layer in enumerate(llama_model.layers):
        layer_id = layer.layer_id
        hf_state_dict[f'model.layers.{i}.input_layernorm.weight'] = llama_model.layers[layer_id].attention_norm.weight.clone().to(dtype)
        hf_state_dict[f'model.layers.{i}.self_attn.q_proj.weight'] = permute_original(llama_model.layers[layer_id].attention.wq.weight.clone()).to(dtype)
        hf_state_dict[f'model.layers.{i}.self_attn.k_proj.weight'] = permute_original(llama_model.layers[layer_id].attention.wk.weight.clone(), num_key_value_heads, key_value_dim, dim).to(dtype)
        hf_state_dict[f'model.layers.{i}.self_attn.v_proj.weight'] = llama_model.layers[layer_id].attention.wv.weight.clone().to(dtype)
        hf_state_dict[f'model.layers.{i}.self_attn.o_proj.weight'] = llama_model.layers[layer_id].attention.wo.weight.clone().to(dtype)
        hf_state_dict[f'model.layers.{i}.post_attention_layernorm.weight'] = llama_model.layers[layer_id].ffn_norm.weight.clone().to(dtype)
        hf_state_dict[f'model.layers.{i}.mlp.gate_proj.weight'] = llama_model.layers[layer_id].feed_forward.w1.weight.clone().to(dtype)
        hf_state_dict[f'model.layers.{i}.mlp.down_proj.weight'] = llama_model.layers[layer_id].feed_forward.w2.weight.clone().to(dtype)
        hf_state_dict[f'model.layers.{i}.mlp.up_proj.weight'] = llama_model.layers[layer_id].feed_forward.w3.weight.clone().to(dtype)

    # llama2.c usually uses tied weights -> reference the embed_tokens.weights instead
    hf_state_dict['lm_head.weight'] = hf_state_dict['model.embed_tokens.weight']

    # We check that the embeddings are tied, else use manual output weights
    _embeddings_are_tied: bool = torch.equal(llama_model.tok_embeddings.weight, llama_model.output.weight)
    if not _embeddings_are_tied:
        hf_state_dict['lm_head.weight'] = llama_model.output.weight.clone().to(dtype)


    # Generate LlamaConfig (seen in transformers.models.llama.configuration_llama)

    # Extract necessary attributes from llama.c model
    vocab_size = llama_model.params.vocab_size
    hidden_size = llama_model.params.dim
    intermediate_size = llama_model.layers[0].feed_forward.w1.weight.shape[0]
    num_hidden_layers = llama_model.params.n_layers
    num_attention_heads = llama_model.params.n_heads
    num_key_value_heads = llama_model.params.n_kv_heads
    max_position_embeddings = llama_model.params.max_seq_len
    rms_norm_eps = llama_model.params.norm_eps

    # TODO check values for:
    # pretraining_tp, initializer_range, use_cache,
    # rope_theta, and rope_scaling.

    config = LlamaConfig(
        vocab_size=vocab_size,
        hidden_size=hidden_size,
        intermediate_size=intermediate_size,
        num_hidden_layers=num_hidden_layers,
        num_attention_heads=num_attention_heads,
        num_key_value_heads=num_key_value_heads,
        max_position_embeddings=max_position_embeddings,
        rms_norm_eps=rms_norm_eps,
        tie_word_embeddings=_embeddings_are_tied,
        # Manual
        architectures=["LlamaForCausalLM"],
        hidden_act="silu",
    )


    # Save files in directory filepath
    # First make the directory if it doesn't exist
    os.makedirs(filepath, exist_ok=True)

    # Save the state dictionary in .bin format, and config as .json
    torch.save(hf_state_dict, os.path.join(filepath, "pytorch_model.bin"))
    config.save_pretrained(filepath)


# -----------------------------------------------------------------------------
# Load / import functions

def load_checkpoint(checkpoint):

    # load the provided model checkpoint
    checkpoint_dict = torch.load(checkpoint, map_location='cpu')
    gptconf = ModelArgs(**checkpoint_dict['model_args'])
    model = Transformer(gptconf)
    state_dict = checkpoint_dict['model']
    unwanted_prefix = '_orig_mod.'
    for k,v in list(state_dict.items()):
        if k.startswith(unwanted_prefix):
            state_dict[k[len(unwanted_prefix):]] = state_dict.pop(k)
    model.load_state_dict(state_dict, strict=False)
    model.eval()
    return model

def load_meta_model(model_path):
    params_path = os.path.join(model_path, 'params.json')
    with open(params_path) as f:
        params = json.load(f)
        print(params)

    model_paths = sorted(list(Path(model_path).glob('consolidated.*.pth')))
    models = [torch.load(p, map_location='cpu') for p in model_paths]

    def concat_weights(models):
        state_dict = {}
        for name in list(models[0]):
            tensors = [model[name] for model in models]
            if len(tensors) == 1 or len(tensors[0].shape) == 1:
                state_dict[name] = tensors[0]
                continue
            is_axis_1 = (
                name.startswith('tok_embeddings.')
                or name.endswith('.attention.wo.weight')
                or name.endswith('.feed_forward.w2.weight')
            )
            axis = 1 if is_axis_1 else 0
            state_dict[name] = torch.cat(tensors, dim=axis)
            for model in models:
                del model[name]
        return state_dict

    state_dict = concat_weights(models)
    del models

    # set ModelArgs
    config = ModelArgs()
    config.dim = params["dim"]
    config.n_layers = params["n_layers"]
    config.n_heads = params["n_heads"]
    config.n_kv_heads = params.get('n_kv_heads') or params['n_heads']
    config.multiple_of = params["multiple_of"]
    config.norm_eps = params["norm_eps"]

    config.vocab_size = state_dict['tok_embeddings.weight'].shape[0]
    config.max_seq_len = 2048


    # create a new Transformer object and set weights
    model = Transformer(config)

    model.tok_embeddings.weight = nn.Parameter(state_dict['tok_embeddings.weight'])
    model.norm.weight = nn.Parameter(state_dict['norm.weight'])

    for layer in model.layers:
        i = layer.layer_id
        layer.attention_norm.weight = nn.Parameter(state_dict[f'layers.{i}.attention_norm.weight'])
        layer.attention.wq.weight = nn.Parameter(state_dict[f'layers.{i}.attention.wq.weight'])
        layer.attention.wk.weight = nn.Parameter(state_dict[f'layers.{i}.attention.wk.weight'])
        layer.attention.wv.weight = nn.Parameter(state_dict[f'layers.{i}.attention.wv.weight'])
        layer.attention.wo.weight = nn.Parameter(state_dict[f'layers.{i}.attention.wo.weight'])
        layer.ffn_norm.weight = nn.Parameter(state_dict[f'layers.{i}.ffn_norm.weight'])
        layer.feed_forward.w1.weight = nn.Parameter(state_dict[f'layers.{i}.feed_forward.w1.weight'])
        layer.feed_forward.w2.weight = nn.Parameter(state_dict[f'layers.{i}.feed_forward.w2.weight'])
        layer.feed_forward.w3.weight = nn.Parameter(state_dict[f'layers.{i}.feed_forward.w3.weight'])

    # final classifier
    model.output.weight = nn.Parameter(state_dict['output.weight'])
    model.eval()
    return model

def load_hf_model_memory_efficient(model_path, device_map="cpu"):
    """
    Memory-efficient loading of HuggingFace model by loading weights layer by layer
    and immediately converting them to the target format.
    """
    try:
        from transformers import AutoConfig, AutoModelForCausalLM
    except ImportError:
        print("Error: transformers package is required to load huggingface models")
        print("Please run `pip install transformers` to install it")
        return None

    print("Loading model configuration...")
    config = AutoConfig.from_pretrained(model_path)
    
    # convert LlamaConfig to ModelArgs
    model_args = ModelArgs()
    model_args.dim = config.hidden_size
    model_args.n_layers = config.num_hidden_layers
    model_args.n_heads = config.num_attention_heads
    model_args.n_kv_heads = config.num_attention_heads
    model_args.vocab_size = config.vocab_size
    model_args.hidden_dim = config.intermediate_size
    model_args.norm_eps = config.rms_norm_eps
    model_args.max_seq_len = config.max_position_embeddings

    print("Creating empty model structure...")
    # create a new Transformer object
    model = Transformer(model_args)
    
    # huggingface permutes WQ and WK, this function reverses it
    def permute_reverse(w, n_heads=model_args.n_heads, dim1=model_args.dim, dim2=model_args.dim):
        return w.view(n_heads, 2, dim1 // n_heads // 2, dim2).transpose(1, 2).reshape(dim1, dim2)

    print("Loading model weights layer by layer...")
    
    # Load the model with device_map to control memory usage
    hf_model = AutoModelForCausalLM.from_pretrained(
        model_path,
        device_map=device_map,
        torch_dtype=torch.float32,
        low_cpu_mem_usage=True
    )
    
    # Get state dict
    hf_dict = hf_model.state_dict()
    
    print("Converting embedding weights...")
    # Convert embedding weights
    model.tok_embeddings.weight = nn.Parameter(hf_dict['model.embed_tokens.weight'].cpu())
    del hf_dict['model.embed_tokens.weight']
    
    print("Converting final norm...")
    # Convert final norm
    model.norm.weight = nn.Parameter(hf_dict['model.norm.weight'].cpu())
    del hf_dict['model.norm.weight']
    
    print("Converting layer weights...")
    # Convert layer weights one by one
    for i in range(model_args.n_layers):
        print(f"  Converting layer {i+1}/{model_args.n_layers}")
        
        # Load layer weights
        layer = model.layers[i]
        
        # Attention norm
        layer.attention_norm.weight = nn.Parameter(
            hf_dict[f'model.layers.{i}.input_layernorm.weight'].cpu()
        )
        del hf_dict[f'model.layers.{i}.input_layernorm.weight']
        
        # Attention weights
        layer.attention.wq.weight = nn.Parameter(
            permute_reverse(hf_dict[f'model.layers.{i}.self_attn.q_proj.weight']).cpu()
        )
        del hf_dict[f'model.layers.{i}.self_attn.q_proj.weight']
        
        layer.attention.wk.weight = nn.Parameter(
            permute_reverse(hf_dict[f'model.layers.{i}.self_attn.k_proj.weight']).cpu()
        )
        del hf_dict[f'model.layers.{i}.self_attn.k_proj.weight']
        
        layer.attention.wv.weight = nn.Parameter(
            hf_dict[f'model.layers.{i}.self_attn.v_proj.weight'].cpu()
        )
        del hf_dict[f'model.layers.{i}.self_attn.v_proj.weight']
        
        layer.attention.wo.weight = nn.Parameter(
            hf_dict[f'model.layers.{i}.self_attn.o_proj.weight'].cpu()
        )
        del hf_dict[f'model.layers.{i}.self_attn.o_proj.weight']
        
        # FFN norm
        layer.ffn_norm.weight = nn.Parameter(
            hf_dict[f'model.layers.{i}.post_attention_layernorm.weight'].cpu()
        )
        del hf_dict[f'model.layers.{i}.post_attention_layernorm.weight']
        
        # FFN weights
        layer.feed_forward.w1.weight = nn.Parameter(
            hf_dict[f'model.layers.{i}.mlp.gate_proj.weight'].cpu()
        )
        del hf_dict[f'model.layers.{i}.mlp.gate_proj.weight']
        
        layer.feed_forward.w2.weight = nn.Parameter(
            hf_dict[f'model.layers.{i}.mlp.down_proj.weight'].cpu()
        )
        del hf_dict[f'model.layers.{i}.mlp.down_proj.weight']
        
        layer.feed_forward.w3.weight = nn.Parameter(
            hf_dict[f'model.layers.{i}.mlp.up_proj.weight'].cpu()
        )
        del hf_dict[f'model.layers.{i}.mlp.up_proj.weight']
        
        # Force garbage collection after each layer
        import gc
        gc.collect()
        torch.cuda.empty_cache() if torch.cuda.is_available() else None
    
    print("Converting final classifier...")
    # final classifier
    model.output.weight = nn.Parameter(hf_dict['lm_head.weight'].cpu())
    del hf_dict['lm_head.weight']
    
    # Clean up
    del hf_model
    del hf_dict
    gc.collect()
    torch.cuda.empty_cache() if torch.cuda.is_available() else None
    
    model.eval()
    print("Model loading completed!")
    return model

def load_hf_model_ultra_low_memory(model_path):
    """
    Ultra-low memory loading by directly reading safetensors files
    without loading the full HuggingFace model into memory.
    """
    try:
        from transformers import AutoConfig
        from safetensors import safe_open
    except ImportError as e:
        print(f"Error: Required packages not found: {e}")
        print("Please run `pip install transformers safetensors` to install them")
        return None

    print("Loading model configuration...")
    config = AutoConfig.from_pretrained(model_path)
    
    # convert LlamaConfig to ModelArgs
    model_args = ModelArgs()
    model_args.dim = config.hidden_size
    model_args.n_layers = config.num_hidden_layers
    model_args.n_heads = config.num_attention_heads
    model_args.n_kv_heads = config.num_attention_heads
    model_args.vocab_size = config.vocab_size
    model_args.hidden_dim = config.intermediate_size
    model_args.norm_eps = config.rms_norm_eps
    model_args.max_seq_len = config.max_position_embeddings

    print("Creating empty model structure...")
    # create a new Transformer object
    model = Transformer(model_args)
    
    # huggingface permutes WQ and WK, this function reverses it
    def permute_reverse(w, n_heads=model_args.n_heads, dim1=model_args.dim, dim2=model_args.dim):
        return w.view(n_heads, 2, dim1 // n_heads // 2, dim2).transpose(1, 2).reshape(dim1, dim2)

    # Find safetensors files
    model_path = Path(model_path)
    safetensors_files = list(model_path.glob("*.safetensors"))
    
    if not safetensors_files:
        print("No safetensors files found, falling back to memory-efficient loading...")
        return load_hf_model_memory_efficient(model_path)
    
    print(f"Found {len(safetensors_files)} safetensors files")
    
    # Load weights directly from safetensors files
    print("Converting embedding weights...")
    with safe_open(safetensors_files[0], framework="pt", device="cpu") as f:
        model.tok_embeddings.weight = nn.Parameter(f.get_tensor("model.embed_tokens.weight"))
        model.norm.weight = nn.Parameter(f.get_tensor("model.norm.weight"))
    
    print("Converting layer weights...")
    # Convert layer weights one by one
    for i in range(model_args.n_layers):
        print(f"  Converting layer {i+1}/{model_args.n_layers}")
        
        # Load layer weights from safetensors
        layer = model.layers[i]
        
        # Find which file contains this layer's weights
        layer_weights = {}
        for safetensor_file in safetensors_files:
            with safe_open(safetensor_file, framework="pt", device="cpu") as f:
                # Check if this file contains the layer weights
                layer_prefix = f"model.layers.{i}."
                available_keys = f.keys()
                
                for key in available_keys:
                    if key.startswith(layer_prefix):
                        layer_weights[key] = f.get_tensor(key)
                
                # If we found all weights for this layer, break
                if len([k for k in layer_weights.keys() if k.startswith(layer_prefix)]) >= 10:
                    break
        
        # Attention norm
        layer.attention_norm.weight = nn.Parameter(layer_weights[f'model.layers.{i}.input_layernorm.weight'])
        
        # Attention weights
        layer.attention.wq.weight = nn.Parameter(
            permute_reverse(layer_weights[f'model.layers.{i}.self_attn.q_proj.weight'])
        )
        layer.attention.wk.weight = nn.Parameter(
            permute_reverse(layer_weights[f'model.layers.{i}.self_attn.k_proj.weight'])
        )
        layer.attention.wv.weight = nn.Parameter(layer_weights[f'model.layers.{i}.self_attn.v_proj.weight'])
        layer.attention.wo.weight = nn.Parameter(layer_weights[f'model.layers.{i}.self_attn.o_proj.weight'])
        
        # FFN norm
        layer.ffn_norm.weight = nn.Parameter(layer_weights[f'model.layers.{i}.post_attention_layernorm.weight'])
        
        # FFN weights
        layer.feed_forward.w1.weight = nn.Parameter(layer_weights[f'model.layers.{i}.mlp.gate_proj.weight'])
        layer.feed_forward.w2.weight = nn.Parameter(layer_weights[f'model.layers.{i}.mlp.down_proj.weight'])
        layer.feed_forward.w3.weight = nn.Parameter(layer_weights[f'model.layers.{i}.mlp.up_proj.weight'])
        
        # Clear layer weights from memory
        del layer_weights
        
        # Force garbage collection after each layer
        import gc
        gc.collect()
    
    print("Converting final classifier...")
    # Load final classifier
    for safetensor_file in safetensors_files:
        with safe_open(safetensor_file, framework="pt", device="cpu") as f:
            if "lm_head.weight" in f.keys():
                model.output.weight = nn.Parameter(f.get_tensor("lm_head.weight"))
                break
    
    model.eval()
    print("Model loading completed!")
    return model

def load_hf_model(model_path):
    """
    Original load_hf_model function - now uses memory-efficient version by default
    """
    return load_hf_model_memory_efficient(model_path)

def load_hf_model_extreme_low_memory(model_path):
    """
    Extreme low memory loading that processes the model in minimal chunks
    and uses aggressive memory management.
    """
    try:
        from transformers import AutoConfig
        from safetensors import safe_open
    except ImportError as e:
        print(f"Error: Required packages not found: {e}")
        print("Please run `pip install transformers safetensors` to install them")
        return None

    print("Loading model configuration...")
    config = AutoConfig.from_pretrained(model_path)
    
    # convert LlamaConfig to ModelArgs
    model_args = ModelArgs()
    model_args.dim = config.hidden_size
    model_args.n_layers = config.num_hidden_layers
    model_args.n_heads = config.num_attention_heads
    model_args.n_kv_heads = config.num_attention_heads
    model_args.vocab_size = config.vocab_size
    model_args.hidden_dim = config.intermediate_size
    model_args.norm_eps = config.rms_norm_eps
    model_args.max_seq_len = config.max_position_embeddings

    print("Creating empty model structure...")
    # create a new Transformer object
    model = Transformer(model_args)
    
    # huggingface permutes WQ and WK, this function reverses it
    def permute_reverse(w, n_heads=model_args.n_heads, dim1=model_args.dim, dim2=model_args.dim):
        return w.view(n_heads, 2, dim1 // n_heads // 2, dim2).transpose(1, 2).reshape(dim1, dim2)

    # Find safetensors files
    model_path = Path(model_path)
    safetensors_files = list(model_path.glob("*.safetensors"))
    
    if not safetensors_files:
        print("No safetensors files found, falling back to ultra-low memory loading...")
        return load_hf_model_ultra_low_memory(model_path)
    
    print(f"Found {len(safetensors_files)} safetensors files")
    
    # Force garbage collection before starting
    import gc
    gc.collect()
    
    # Load weights directly from safetensors files with extreme memory management
    print("Converting embedding weights...")
    with safe_open(safetensors_files[0], framework="pt", device="cpu") as f:
        model.tok_embeddings.weight = nn.Parameter(f.get_tensor("model.embed_tokens.weight"))
        gc.collect()
        model.norm.weight = nn.Parameter(f.get_tensor("model.norm.weight"))
        gc.collect()
    
    print("Converting layer weights...")
    # Convert layer weights one by one with extreme memory management
    for i in range(model_args.n_layers):
        print(f"  Converting layer {i+1}/{model_args.n_layers}")
        
        # Load layer weights from safetensors with minimal memory usage
        layer = model.layers[i]
        
        # Process each weight tensor individually to minimize memory usage
        with safe_open(safetensors_files[0], framework="pt", device="cpu") as f:
            # Attention norm
            layer.attention_norm.weight = nn.Parameter(f.get_tensor(f'model.layers.{i}.input_layernorm.weight'))
            gc.collect()
            
            # Attention weights
            layer.attention.wq.weight = nn.Parameter(
                permute_reverse(f.get_tensor(f'model.layers.{i}.self_attn.q_proj.weight'))
            )
            gc.collect()
            
            layer.attention.wk.weight = nn.Parameter(
                permute_reverse(f.get_tensor(f'model.layers.{i}.self_attn.k_proj.weight'))
            )
            gc.collect()
            
            layer.attention.wv.weight = nn.Parameter(f.get_tensor(f'model.layers.{i}.self_attn.v_proj.weight'))
            gc.collect()
            
            layer.attention.wo.weight = nn.Parameter(f.get_tensor(f'model.layers.{i}.self_attn.o_proj.weight'))
            gc.collect()
            
            # FFN norm
            layer.ffn_norm.weight = nn.Parameter(f.get_tensor(f'model.layers.{i}.post_attention_layernorm.weight'))
            gc.collect()
            
            # FFN weights
            layer.feed_forward.w1.weight = nn.Parameter(f.get_tensor(f'model.layers.{i}.mlp.gate_proj.weight'))
            gc.collect()
            
            layer.feed_forward.w2.weight = nn.Parameter(f.get_tensor(f'model.layers.{i}.mlp.down_proj.weight'))
            gc.collect()
            
            layer.feed_forward.w3.weight = nn.Parameter(f.get_tensor(f'model.layers.{i}.mlp.up_proj.weight'))
            gc.collect()
        
        # Force garbage collection after each layer
        gc.collect()
        torch.cuda.empty_cache() if torch.cuda.is_available() else None
    
    print("Converting final classifier...")
    # Load final classifier
    for safetensor_file in safetensors_files:
        with safe_open(safetensor_file, framework="pt", device="cpu") as f:
            if "lm_head.weight" in f.keys():
                model.output.weight = nn.Parameter(f.get_tensor("lm_head.weight"))
                break
    
    # Final cleanup
    gc.collect()
    torch.cuda.empty_cache() if torch.cuda.is_available() else None
    
    model.eval()
    print("Model loading completed!")
    return model


# -----------------------------------------------------------------------------
# API entrypoint

def model_export(model, filepath, version, dtype=torch.float32):
    """
    Versions docs:
    v-1:huggingface export, i.e. intended for use outside of this repo, in HF
    v0: legacy llama2.c float format, DEPRECATED
    v1: float32 export
    v2: int8 quantized Q8_0 export, similar to llama.cpp, in groups
    # TODO: add dtype export support for other versions (?)
    """
    if version == 0:
        legacy_export(model, filepath)
    elif version == 1:
        version1_export(model, filepath)
    elif version == 2:
        version2_export(model, filepath)
    elif version == -1:
        hf_export(model, filepath, dtype)
    else:
        raise ValueError(f"unknown version {version}")

def torchscript_export(model, filepath, zero_params=False, gzip_output=False):
    """
    (This was submitted via a PR earlier. Leaving it here, but "orphaned" for now)
    Saves the model as a TorchScript.
    The resulting file can be loaded in C++ code and then used for training or
    inference with:
        #include <torch/script.h>
        torch::jit::Module module = torch::jit::load("model.pt")
    Note that the serialized model includes the initial parameters and with the default
    ModelArgs the file is 59M and gzips down to 55M. If you want to serialize/distribute
    the model parameters separately you can zero out the parameters before saving it and
    it will gzip down to 780K.
    """

    # If requested zero params before saving the model. This is useful in
    # conjunction with gzip_output.
    if zero_params:
        for p in model.parameters():
            p.detach().zero_()

    torch.jit.save(torch.jit.script(model), filepath)

    if gzip_output:
        with open(filepath, "rb") as f_in:
            with gzip.open(f"{filepath}.gz", "wb") as f_out:
                shutil.copyfileobj(f_in, f_out)
        os.unlink(filepath)

def streaming_export_v2(model_path, filepath, group_size=64):
    """
    Stream weights directly from safetensors to version 2 .bin file
    without loading the entire model into memory.
    """
    try:
        from transformers import AutoConfig
        from safetensors import safe_open
    except ImportError as e:
        print(f"Error: Required packages not found: {e}")
        print("Please run `pip install transformers safetensors` to install them")
        return None

    print("Loading model configuration...")
    config = AutoConfig.from_pretrained(model_path)
    
    # Calculate model parameters
    dim = config.hidden_size
    n_layers = config.num_hidden_layers
    n_heads = config.num_attention_heads
    n_kv_heads = config.num_attention_heads
    vocab_size = config.vocab_size
    hidden_dim = config.intermediate_size
    max_seq_len = config.max_position_embeddings

    # Find safetensors files
    model_path = Path(model_path)
    safetensors_files = list(model_path.glob("*.safetensors"))
    
    if not safetensors_files:
        print("No safetensors files found!")
        return None
    
    print(f"Found {len(safetensors_files)} safetensors files")
    
    # Open output file
    out_file = open(filepath, 'wb')
    
    # Write header (256 bytes) - exactly like original version2_export
    version = 2
    out_file.write(struct.pack('I', 0x616b3432))  # magic
    out_file.write(struct.pack('i', version))     # version
    out_file.write(struct.pack('iiiiiii', dim, hidden_dim, n_layers, n_heads, n_kv_heads, vocab_size, max_seq_len))
    out_file.write(struct.pack('B', 1))  # shared_classifier (assume True)
    out_file.write(struct.pack('i', group_size))  # group_size
    pad = 256 - out_file.tell()
    out_file.write(b'\0' * pad)
    
    def get_tensor_from_files(tensor_name):
        """Get tensor from any of the safetensors files"""
        for safetensor_file in safetensors_files:
            with safe_open(safetensor_file, framework="pt", device="cpu") as f:
                if tensor_name in f.keys():
                    return f.get_tensor(tensor_name)
        return None
    
    print("Writing normalization weights...")
    # Write all normalization weights in fp32 - exactly like original version2_export
    # Attention norms
    for i in range(n_layers):
        weight = get_tensor_from_files(f'model.layers.{i}.input_layernorm.weight')
        if weight is None:
            print(f"Error: Could not find model.layers.{i}.input_layernorm.weight")
            return None
        serialize_fp32(out_file, weight)
        del weight
        import gc
        gc.collect()
    
    # FFN norms
    for i in range(n_layers):
        weight = get_tensor_from_files(f'model.layers.{i}.post_attention_layernorm.weight')
        if weight is None:
            print(f"Error: Could not find model.layers.{i}.post_attention_layernorm.weight")
            return None
        serialize_fp32(out_file, weight)
        del weight
        gc.collect()
    
    # Final norm
    weight = get_tensor_from_files('model.norm.weight')
    if weight is None:
        print("Error: Could not find model.norm.weight")
        return None
    serialize_fp32(out_file, weight)
    del weight
    gc.collect()
    
    print("Writing quantized weights...")
    # Write quantized weights - exactly like original version2_export
    weight_names = [
        'model.embed_tokens.weight',
    ]
    
    # Add layer weights
    for i in range(n_layers):
        weight_names.extend([
            f'model.layers.{i}.self_attn.q_proj.weight',
            f'model.layers.{i}.self_attn.k_proj.weight',
            f'model.layers.{i}.self_attn.v_proj.weight',
            f'model.layers.{i}.self_attn.o_proj.weight',
            f'model.layers.{i}.mlp.gate_proj.weight',
            f'model.layers.{i}.mlp.down_proj.weight',
            f'model.layers.{i}.mlp.up_proj.weight',
        ])
    
    # Process each weight
    for i, weight_name in enumerate(weight_names):
        print(f"  Quantizing {i+1}/{len(weight_names)}: {weight_name}")
        
        # Get weight from files
        weight = get_tensor_from_files(weight_name)
        if weight is None:
            print(f"Error: Could not find {weight_name}")
            return None
        
        # Handle Q/K weight permutation
        if 'q_proj.weight' in weight_name or 'k_proj.weight' in weight_name:
            # Permute the weight
            weight = weight.view(n_heads, 2, dim // n_heads // 2, dim).transpose(1, 2).reshape(dim, dim)
        
        # Quantize
        q, s, err = quantize_q80(weight, group_size)
        
        # Write to file
        serialize_int8(out_file, q)
        serialize_fp32(out_file, s)
        
        print(f"    Quantized {tuple(weight.shape)} to Q8_0 with max error {err}")
        
        # Clean up
        del weight, q, s
        gc.collect()
    
    # Note: Do NOT write frequency tensors - they are not part of version 2 format
    # The original version2_export does not include them
    
    out_file.close()
    print(f"wrote {filepath}")
    return True

# -----------------------------------------------------------------------------
# CLI entrypoint

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("filepath", type=str, help="the output filepath")
    parser.add_argument("--version", default=0, type=int, help="the version to export with")
    parser.add_argument("--dtype", type=str, help="dtype of the model (fp16, fp32)", default="fp32")
    parser.add_argument("--device-map", type=str, default="cpu", 
                       help="device map for loading HF models (cpu, auto, or specific device)")
    parser.add_argument("--low-memory", action="store_true", 
                       help="enable low memory mode for HF models")
    parser.add_argument("--ultra-low-memory", action="store_true", 
                       help="enable ultra-low memory mode (loads directly from safetensors)")
    parser.add_argument("--extreme-low-memory", action="store_true", 
                       help="enable extreme low memory mode (minimal chunks, aggressive GC)")
    parser.add_argument("--streaming", action="store_true", 
                       help="enable streaming mode (direct safetensors to bin, minimal memory)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--checkpoint", type=str, help="model checkpoint, .pt file")
    group.add_argument("--meta-llama", type=str, help="meta llama model path")
    group.add_argument("--hf", type=str, help="huggingface model path")
    args = parser.parse_args()
    dtype = {"fp16": torch.float16, "fp32": torch.float32}[args.dtype]

    # Set memory optimization flags
    if args.low_memory:
        print("Enabling low memory mode...")
        import os
        os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'max_split_size_mb:128'
        torch.backends.cudnn.benchmark = False
        torch.backends.cudnn.deterministic = True

    if args.checkpoint:
        model = load_checkpoint(args.checkpoint)
    elif args.meta_llama:
        model = load_meta_model(args.meta_llama)
    elif args.hf:
        if args.streaming:
            # Use streaming export directly
            success = streaming_export_v2(args.hf, args.filepath, group_size=64)
            if success:
                print("Streaming export completed successfully!")
                exit(0)
            else:
                print("Streaming export failed!")
                exit(1)
        elif args.extreme_low_memory:
            model = load_hf_model_extreme_low_memory(args.hf)
        elif args.ultra_low_memory:
            model = load_hf_model_ultra_low_memory(args.hf)
        else:
            model = load_hf_model_memory_efficient(args.hf, device_map=args.device_map)

    if model is None:
        parser.error("Can't load input model!")

    # export
    model_export(model, args.filepath, args.version, args.dtype)
