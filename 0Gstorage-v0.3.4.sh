#!/bin/bash

# 컬러 정의
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BOLD_BLUE='\033[1;34m'
export NC='\033[0m'  # No Color

# 사전안내
echo -e "${RED}트잭봇은 필수로 버너지갑을 이용하세요${NC}"

# 설치할 Node.js 버전 설정 (예: 18.x LTS)
NODE_VERSION="18.x"

if ! command -v node &> /dev/null
then
    echo -e "${BOLD_BLUE}Node.js가 설치되지 않았습니다. Node.js ${NODE_VERSION}를 설치합니다...${NC}"
    echo
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo -e "${BOLD_BLUE}Node.js가 이미 설치되어 있습니다.${NC}"
fi
echo
if ! command -v npm &> /dev/null
then
    echo -e "${BOLD_BLUE}npm이 설치되지 않았습니다. npm을 설치합니다...${NC}"
    echo
    sudo apt-get install -y npm
else
    echo -e "${BOLD_BLUE}npm이 이미 설치되어 있습니다.${NC}"
fi
echo
echo -e "${BOLD_BLUE}프로젝트 디렉토리를 생성하고 해당 디렉토리로 이동합니다.${NC}"
mkdir -p SolanaTx
cd SolanaTx
echo
echo -e "${BOLD_BLUE}새로운 Node.js 프로젝트를 초기화합니다.${NC}"
echo
npm init -y
echo
echo -e "${BOLD_BLUE}필요한 패키지를 설치합니다.${NC}"
echo
npm install @solana/web3.js chalk bs58
echo
echo -e "${BOLD_BLUE}개인키를 입력해야합니다.${NC}"
echo
read -p "Solana 월렛의 개인키를 입력하세요 (Base58로 인코딩된 문자열): " privkey
read -p "수신자의 주소를 입력하세요: " toPubkey
echo
echo -e "${BOLD_BLUE}Node.js 스크립트 파일을 생성합니다.${NC}"
echo
cat << EOF > send_tx.mjs
import web3 from "@solana/web3.js";
import chalk from "chalk";
import bs58 from "bs58";

// 연결 설정
const connection = new web3.Connection("https://api.mainnet-beta.solana.com", 'confirmed');

// 개인키 및 수신자 주소 설정
const privkey = "$privkey";
const from = web3.Keypair.fromSecretKey(bs58.decode(privkey));
const toPubkey = new web3.PublicKey("$toPubkey");

// 전송할 SOL의 양 설정 (여기서는 0 SOL을 보내는 트랜잭션을 구성)
const amount = web3.LAMPORTS_PER_SOL * 0; // 0 SOL

(async () => {
    const transaction = new web3.Transaction().add(
        web3.SystemProgram.transfer({
            fromPubkey: from.publicKey,
            toPubkey: toPubkey,
            lamports: amount,
        }),
    );

    // Compute budget 설정 (선택 사항: 필요한 경우에만 설정)
    const computeUnits = new web3.ComputeBudgetProgram.SetComputeUnitLimit({
        units: 1400000,
    });
    transaction.add(computeUnits);

    try {
        console.log(chalk.yellow('Sending transaction...'));
        const signature = await web3.sendAndConfirmTransaction(
            connection,
            transaction,
            [from],
        );
        console.log(chalk.blue('Tx hash :'), signature);
    } catch (error) {
        console.error(chalk.red('Transaction failed:'), error);
    }

    console.log(chalk.green('Transaction completed.'));
})();
EOF
echo
echo -e "${BOLD_BLUE}Node.js 스크립트를 실행합니다.${NC}"
node send_tx.mjs
echo
echo -e "${YELLOW}모든 작업이 완료되었습니다. 컨트롤+A+D로 스크린을 종료해주세요.${NC}"
echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"

