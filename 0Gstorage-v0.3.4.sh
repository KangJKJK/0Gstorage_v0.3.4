#!/bin/bash

# 컬러 정의
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'  # No Color

execute_in_screen() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    screen -S 0glabs -X stuff "$command$(echo -e '\n')"
}

# 1. screen 설치
echo "Installing screen..."
sudo apt update && sudo apt install -y screen

# 2. 새로운 screen 세션 생성
echo "Creating a new screen session named '0glabs'..."
screen -S 0glabs -dm bash

# 3. 패키지 업데이트 및 필수 패키지 설치
execute_in_screen "Updating package lists..." "sudo apt-get update"
execute_in_screen "Installing clang, cmake, and build-essential..." "sudo apt-get install -y clang cmake build-essential"

# 4. Go 설치
execute_in_screen "Downloading Go 1.22.0..." "wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz"
execute_in_screen "Removing old Go installation and extracting new Go version..." "sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz"
execute_in_screen "Adding Go to PATH..." "export PATH=\$PATH:/usr/local/go/bin"

# 5. Rust 설치
execute_in_screen "Installing Rust..." "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"

# 6. zgs.service 중지 및 제거
execute_in_screen "Stopping and disabling zgs.service..." "sudo systemctl stop zgs.service"
execute_in_screen "Removing zgs.service..." "sudo systemctl disable zgs.service && sudo rm /etc/systemd/system/zgs.service"

# 7. 기존 0g-storage-node 디렉토리 제거 및 새로운 리포지토리 클론
execute_in_screen "Removing old 0g-storage-node directory..." "sudo rm -rf \$HOME/0g-storage-node"
execute_in_screen "Installing git..." "sudo apt install -y git"
execute_in_screen "Cloning 0g-storage-node repository..." "git clone https://github.com/0glabs/0g-storage-node.git"
execute_in_screen "Checking out specific commit 7d73ccd..." "cd \$HOME/0g-storage-node && git checkout 7d73ccd"
execute_in_screen "Initializing git submodules..." "git submodule update --init"

# 8. Cargo 설치 및 빌드
execute_in_screen "Installing Cargo..." "sudo apt install -y cargo"
execute_in_screen "Building the 0g-storage-node with Cargo..." "cargo build --release"

# 9. 0G_STORAGE_CONFIG.sh 스크립트 다운로드 및 실행
execute_in_screen "Downloading 0G_STORAGE_CONFIG.sh..." "sudo wget -O \$HOME/0G_STORAGE_CONFIG.sh https://0g.service.nodebrand.xyz/0G/0G_STORAGE_CONFIG.sh"
execute_in_screen "Making 0G_STORAGE_CONFIG.sh executable..." "chmod +x \$HOME/0G_STORAGE_CONFIG.sh"
execute_in_screen "Executing 0G_STORAGE_CONFIG.sh..." "\$HOME/0G_STORAGE_CONFIG.sh"

# 10. zgs.service 파일 생성
execute_in_screen "Creating zgs.service file..." "sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
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

# 11. UFW 설치 및 포트 개방
execute_in_screen "Installing UFW..." "sudo apt-get install -y ufw"
execute_in_screen "Enabling UFW..." "sudo ufw enable"
execute_in_screen "Allowing necessary ports through UFW..." \
    "sudo ufw allow ssh && \
     sudo ufw allow 26658 && \
     sudo ufw allow 26656 && \
     sudo ufw allow 6060 && \
     sudo ufw allow 1317 && \
     sudo ufw allow 9090 && \
     sudo ufw allow 9091"

# 12. Systemd 서비스 재로드 및 zgs 서비스 시작
execute_in_screen "Reloading systemd and starting zgs service..." "sudo systemctl daemon-reload && sudo systemctl enable zgs && sudo systemctl start zgs"

echo -e "${YELLOW}모든작업이 완료되었습니다.컨트롤+A+D로 스크린을 종료해주세요${NC}"
# 스크립트 작성자: kangjk