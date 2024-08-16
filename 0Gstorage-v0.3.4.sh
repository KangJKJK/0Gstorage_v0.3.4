#!/bin/bash

# 컬러 정의
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'  # No Color

execute_and_prompt() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    eval "$command"
    echo -e "${GREEN}Done.${NC}"
}

# 1. 패키지 업데이트 및 필수 패키지 설치
execute_and_prompt "Updating package lists..." "sudo apt-get update"
execute_and_prompt "Installing clang, cmake, and build-essential..." "sudo apt-get install -y clang cmake build-essential"

# 2. Go 설치
execute_and_prompt "Downloading Go 1.22.0..." "wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz"
execute_and_prompt "Removing old Go installation and extracting new Go version..." "sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz"
execute_and_prompt "Adding Go to PATH..." "export PATH=\$PATH:/usr/local/go/bin"

# 3. Rust 설치
execute_and_prompt "Installing Rust..." "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"

# 4. zgs.service 중지 및 제거
execute_and_prompt "Stopping and disabling zgs.service..." "sudo systemctl stop zgs.service"
execute_and_prompt "Removing zgs.service..." "sudo systemctl disable zgs.service && sudo rm /etc/systemd/system/zgs.service"

# 5. 기존 0g-storage-node 디렉토리 제거 및 새로운 리포지토리 클론
execute_and_prompt "Removing old 0g-storage-node directory..." "sudo rm -rf \$HOME/0g-storage-node"
execute_and_prompt "Installing git..." "sudo apt install -y git"
execute_and_prompt "Cloning 0g-storage-node repository..." "git clone https://github.com/0glabs/0g-storage-node.git"
cd $HOME/0g-storage-node
execute_and_prompt "Checking out specific commit 7d73ccd..." "git checkout 7d73ccd"
execute_and_prompt "Initializing git submodules..." "git submodule update --init"

# 6. Cargo 설치 및 빌드
execute_and_prompt "Installing Cargo..." "sudo apt install -y cargo"
execute_and_prompt "Building the 0g-storage-node with Cargo..." "cargo build --release"

# 7. 0G_STORAGE_CONFIG.sh 스크립트 다운로드 및 실행
execute_and_prompt "Downloading 0G_STORAGE_CONFIG.sh..." "sudo wget -O \$HOME/0G_STORAGE_CONFIG.sh https://0g.service.nodebrand.xyz/0G/0G_STORAGE_CONFIG.sh"
execute_and_prompt "Making 0G_STORAGE_CONFIG.sh executable..." "chmod +x \$HOME/0G_STORAGE_CONFIG.sh"
execute_and_prompt "Executing 0G_STORAGE_CONFIG.sh..." "\$HOME/0G_STORAGE_CONFIG.sh"

# 8. zgs.service 파일 생성
execute_and_prompt "Creating zgs.service file..." "sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=root
WorkingDirectory=\$ZGS_HOME/run
ExecStart=\$ZGS_HOME/target/release/zgs_node --config \$ZGS_HOME/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF"

# 9. Systemd 서비스 재로드 및 zgs 서비스 시작
execute_and_prompt "Reloading systemd and starting zgs service..." "sudo systemctl daemon-reload && sudo systemctl enable zgs && sudo systemctl start zgs"

echo -e "${GREEN}All tasks completed successfully!${NC}"