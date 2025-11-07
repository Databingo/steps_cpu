#!/bin/sh -f
args="";
#
# Save current environment settings
#
IPTB_LD_LIBRARY_PATH=$LD_LIBRARY_PATH;
export IPTB_LD_LIBRARY_PATH;
IPTB_PATH=$PATH;
export IPTB_PATH;
#
# Process command line arguments
#
line="$*";
for param in "$@" ; do
 # quote all params
 args="$args \"$param\""
 shift;
done;
#
# Find flow_dir command line argument
#
flowdir=`echo $args | sed 's/.*-flow_dir:\([^ "]*\).*/\1/'`;
altflowdir=`echo $args | sed 's/.*-alt_flow_dir:\([^ "]*\).*/\1/'`;
#
#
#
if [ ! -f $altflowdir/flowmanager.jar ]
then
  echo "ERROR: Illegal -alt_flow_dir definition: $altflowdir";
  exit -1
fi
if [ ! -f $flowdir/launcher.jar ]
then
  echo "ERROR: Illegal -flow_dir definition: $flowdir";
  exit -1
fi
#
# Restore user's path and ls_library_path settings
#
if [ `uname` = "SunOS" ]; then
PLATFORM="solaris";
else
PLATFORM="linux";
fi
LD_LIBRARY_PATH=${QUARTUS_ORIG_LIBPATH:=$LD_LIBRARY_PATH}:${altflowdir}:${QUARTUS_ROOTDIR}/${PLATFORM};
export LD_LIBRARY_PATH;
PATH=${QUARTUS_ORIG_PATH:=$PATH};
export PATH;
#
# Launch IPTB
#
sh -c "${altflowdir}/ip_toolbench $args"
