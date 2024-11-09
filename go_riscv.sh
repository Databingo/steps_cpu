# From golang 1.15.x support riscv
env GOOS=linux GOARCH=riscv64 CGO_ENABLED=1 CC=riscv64-linux-gnu-gcc go build rvasm64I.go
../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-objdump -d rvasm64I
