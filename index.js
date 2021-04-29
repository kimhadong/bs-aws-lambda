const serviceDBJob = require("./src/ServiceDBJob.bs");
const kakao = require("./src/Kakao.bs")

const { existsSync } = require('fs');

const binaryPath = '/tmp/query-engine-rhel-openssl-1.0.x';
if (!existsSync(binaryPath)) {
  const { spawnSync } = require('child_process');

  spawnSync('cp', [
    `${process.env.LAMBDA_TASK_ROOT}/query-engine-rhel-openssl-1.0.x`,
    '/tmp/',
  ]);

  spawnSync('chmod', [`555`, '/tmp/query-engine-rhel-openssl-1.0.x']);
}

exports.serviceDBJobHandler = serviceDBJob.handler;
exports.kakaoHandler = kakao.handler