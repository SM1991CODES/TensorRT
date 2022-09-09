#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# AUTHOR: Sambit Mohapatra
# 
# DATE: 17/08/2022, Valeo, Bietigheim
#
# DESCP: Script to install ROS + Torch-Tensorrt and setup a ssh user vrs/1234 inside a CUDA+CUDNN docker container
#
# BASE IMAGE: docker pull nvcr.io/nvidia/tensorrt:22.08-py3
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

apt-get update
apt-get install sudo
apt-get install net-tools
apt-get install lsb-release
apt-get install curl zip unzip
apt-get install openssh-server
service ssh stop
echo "Port 22102" >> /etc/ssh/sshd_config # change port to 22102
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config # so we can ssh using password
echo "service ssh restart" >> ~/.bashrc # this makes sure ssh starts when container is launched
echo "echo \"=== docker: port: 22102, user: vrs, pass: 1234 ===\"" >> ~/.bashrc 
apt install software-properties-common
apt-get install gdb
apt-get install python-is-python3
apt-get install python3-pip
echo "======== adding user vrs, ALWAYS set pass to 1234 ==========="
adduser vrs
usermod -aG sudo vrs
source ~/.bashrc

echo "Adding CUDA/CUDNN to vrs path..."
echo "export PATH=/usr/local/cuda-11.7/bin${PATH:+:${PATH}}" >> /home/vrs/.bashrc  # so that user has nvcc on path
echo "export LD_LIBRARY_PATH=/usr/local/cuda-11.7/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" >> /home/vrs/.bashrc

echo "=================== BASIC SW INSTALL COMPLETE =============="

echo "============== INSTALLING ROS NOETIC======================="
wget -c https://raw.githubusercontent.com/qboticslabs/ros_install_noetic/master/ros_install_noetic.sh && chmod +x ./ros_install_noetic.sh && ./ros_install_noetic.sh
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

echo "Adding ROS to vrs path..."
echo "source /opt/ros/noetic/setup.bash" >> /home/vrs/.bashrc
echo "================== ROS NOETIC DESKTOP INSTALL COMPLETE =================="


# echo "=========== INSTALLING TENSORRT ===================="
# apt-get install tensorrt-dev
# sudo apt-get install tensorrt-libs
# python3 -m pip install numpy
# apt-get install python3-libnvinfer
# echo "============== TENSORRT INSTALL COMPLETE============"

echo "============== INSTALLING PYTORCH ==============="
pip install torch==1.11.0+cu113 torchvision==0.12.0+cu113 torchaudio==0.11.0 --extra-index-url https://download.pytorch.org/whl/cu113
echo "============ PYTORCH INSTALLATION COMPLETE =========="

# apt-get install git

echo "======= INSTALLING TORCH_TENSORRT============"
echo "========== STAGE 1: BUILDING BAZEL =========="
apt install default-jdk
# git clone -b v1.1.1 https://github.com/SM1991CODES/TensorRT.git
cd ..
export BAZEL_VERSION=$(cat tensorrt/.bazelversion)
mkdir bazel
cd bazel
curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-dist.zip
unzip bazel-$BAZEL_VERSION-dist.zip
bash ./compile.sh
cp output/bazel /usr/local/bin/
cd ..
echo "======== BAZEL BUILD DONE, COPIED TO /usr/local/bin ============"

echo "========= STAGE 2: BUILDING TORCH-TENSORRT C++ ==========="
cd TensorRT/
bazel build //:libtorchtrt --config pre_cxx11_abi -c opt --distdir third_party/distdir/x86_64-linux-gnu
echo "A tarball with the include files and library can then be found in bazel-bin"


echo "====== STAGE 2: BUILDING TORCh-TENSORRT PYTHON ============="
python3 py/setup.py install
