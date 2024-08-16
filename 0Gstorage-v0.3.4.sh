#!/bin/bash

# 컬러 정의
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'  # No Color

# 함수: 명령어 실행 및 결과 확인
execute_command() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    echo "Executing: $command"
    eval "$command"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Command failed: $command${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Success: Command completed successfully.${NC}"
}

# 함수: 명령어 실행 및 오류 무시
execute_command_ignore_errors() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    echo "Executing: $command"
    eval "$command"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Warning: Command failed but continuing: $command${NC}" >&2
    else
        echo -e "${GREEN}Success: Command completed successfully.${NC}"
    fi
}

# 1. 패키지 업데이트 및 필수 패키지 설치
execute_command "패키지 업데이트 중..." "sudo apt-get update"
read -p "설치하려는 패키지들에 대한 권한을 부여하려면 Enter를 누르세요..."
execute_command "필수 패키지 설치 중..." "sudo apt-get install -y clang cmake build-essential"
sleep 5

# 2. Go 설치
execute_command "Go 1.22.0 다운로드 중..." "wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz"
sleep 5

execute_command "Go 설치 후, 경로 추가 중..." "sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz"
export PATH=$PATH:/usr/local/go/bin
echo "PATH=$PATH"  # 경로가 제대로 추가되었는지 확인
sleep 5

# 3. Rust 설치
execute_command "Rust 설치 중..." "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
sleep 5

# 4. zgs.service 중지 및 제거
execute_command_ignore_errors "zgs.service 중지 중..." "sudo systemctl stop zgs.service"
execute_command_ignore_errors "zgs.service 비활성화 및 제거 중..." "sudo systemctl disable zgs.service && sudo rm /etc/systemd/system/zgs.service"
sleep 5

# 5. 0g-storage-node 디렉토리 제거 및 리포지토리 클론
execute_command "기존 0g-storage-node 디렉토리 제거 중..." "sudo rm -rf $HOME/0g-storage-node"
execute_command "git 설치 중..." "sudo apt install -y git"
read -p "Git을 설치한 후 계속하려면 Enter를 누르세요..."
execute_command "0g-storage-node 리포지토리 클론 중..." "git clone https://github.com/0glabs/0g-storage-node.git"
execute_command "특정 커밋 체크아웃 중..." "cd $HOME/0g-storage-node && git checkout 7d73ccd"
execute_command "git 서브모듈 초기화 중..." "git submodule update --init"
execute_command "Cargo 설치 중..." "sudo apt install -y cargo"
read -p "Cargo를 설치한 후 계속하려면 Enter를 누르세요..."
echo -e "${YELLOW}0g-storage-node 빌드 중...${NC}"
cargo build --release
echo -e "${GREEN}0g-storage-node 빌드 완료.${NC}"
sleep 10

# 6. 0G_STORAGE_CONFIG.sh 다운로드 및 실행
execute_command "0G_STORAGE_CONFIG.sh 다운로드 중..." "sudo wget -O $HOME/0G_STORAGE_CONFIG.sh https://0g.service.nodebrand.xyz/0G/0G_STORAGE_CONFIG.sh"
execute_command "0G STORAGE_CONFIG.sh 실행 권한 추가 중..." "chmod +x $HOME/0G_STORAGE_CONFIG.sh"
execute_command "0G_STORAGE_CONFIG.sh 실행 중..." "$HOME/0G_STORAGE_CONFIG.sh"
sleep 10

# 7. zgs.service 파일 생성
execute_command "zgs.service 파일 생성 중..." "sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
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
sleep 5

# 8. UFW 설치 및 포트 개방
execute_command "UFW 설치 중..." "sudo apt-get install -y ufw"
read -p "UFW를 설치한 후 계속하려면 Enter를 누르세요..."
execute_command "UFW 활성화 중..." "sudo ufw enable"
execute_command "필요한 포트 개방 중..." \
    "sudo ufw allow ssh && \
     sudo ufw allow 26658 && \
     sudo ufw allow 26656 && \
     sudo ufw allow 6060 && \
     sudo ufw allow 1317 && \
     sudo ufw allow 9090 && \
     sudo ufw allow 9091"
sleep 5

# 9. Systemd 서비스 재로드 및 zgs 서비스 시작
execute_command "Systemd 서비스 재로드 중..." "sudo systemctl daemon-reload"
execute_command "zgs 서비스 활성화 중..." "sudo systemctl enable zgs"
execute_command "zgs 서비스 시작 중..." "sudo systemctl start zgs"
sleep 5

# 10. 로그 확인
execute_command "로그 확인 중..." "tail -f \$ZGS_HOME/run/log/zgs.log.\$(TZ=UTC date +%Y-%m-%d)"
sleep 5

echo -e "${GREEN}모든 작업이 완료되었습니다. 스크립트 실행을 종료합니다.${NC}"
echo -e "${GREEN}스크립트작성자-kangjk${NC}"
