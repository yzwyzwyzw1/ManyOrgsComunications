#如果修改了部分文件就执行如下命令重新向远程服务器发送修改后的文件


# orderer
.PHONY: orderer-resendConfigFiles
orderer-resendConfigFiles:
	@scp ./fixtures/docker-orderer.yaml root@207.246.88.170:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures

.PHONY: orderer-resendConfigFiles2
orderer-resendConfigFiles2:
	@scp -r ./crypto-config/ordererOrganizations root@207.246.88.170:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/crypto-config
	@scp    ./channel-artifacts/genesis.block root@207.246.88.170:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/channel-artifacts
.PHONY: orderer-down
orderer-down:
	@ssh root@207.246.88.170 "docker-compose -f  /home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/docker-orderer.yaml down; docker ps"
.PHONY: orderer-up
orderer-up:
	@ssh root@207.246.88.170 "docker-compose -f  /home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/docker-orderer.yaml up -d; docker ps"

.PHONY: orderer-restart
orderer-restart: orderer-down orderer-up

# peer0org1
.PHONY: peer0org1-resendConfigFiles2
peer0org1-resendConfigFiles2:
	@scp -r ./crypto-config/peerOrganizations/org1.example.com root@45.63.14.242:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/crypto-config/peerOrganizations
	@scp ./channel-artifacts/mychannel.tx root@45.63.14.242:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/channel-artifacts
	@scp ./channel-artifacts/Org1MSPanchors.tx root@45.63.14.242:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/channel-artifacts
.PHONY: peer0org1-resendConfigFiles
peer0org1-resendConfigFiles:
	@scp ./fixtures/docker-peer0org1.yaml root@45.63.14.242:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures

.PHONY: peer0org1-up
peer0org1-up:
	@ssh root@45.63.14.242 "docker-compose -f  /home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/docker-peer0org1.yaml up -d; docker ps"

.PHONY: peer0org1-down
peer0org1-down:
	@ssh root@45.63.14.242 "docker-compose -f  /home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/docker-peer0org1.yaml down; docker ps"
.PHONY: peer0org1-clean
peer0org1-clean:
	@ssh root@45.63.14.242  "docker volume prune -f ; docker network prune -f ; docker rm -f -v `docker ps -a --no-trunc | grep "mycc" | cut -d ' ' -f 1` 2>/dev/null || true ; docker rmi `docker images --no-trunc | grep "mycc" | cut -d ' ' -f 1` 2>/dev/null || true; docker ps"
.PHONY: peer0org1-restart
peer0org1-restart: peer0org1-down peer0org1-up

# peer0org2
.PHONY: peer0org2-resendConfigFiles2
peer0org2-resendConfigFiles2:
	@scp -r ./crypto-config/peerOrganizations/org2.example.com root@45.77.200.129:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/crypto-config/peerOrganizations
	@scp ./channel-artifacts/mychannel.tx root@45.77.200.129:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/channel-artifacts
	@scp ./channel-artifacts/Org2MSPanchors.tx root@45.77.200.129:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/channel-artifacts
.PHONY: peer0org2-resendConfigFiles
peer0org2-resendConfigFiles:
	@scp ./fixtures/docker-peer0org2.yaml root@45.77.200.129:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures

.PHONY: peer0org2-up
peer0org2-up:
	@ssh root@45.77.200.129 "docker-compose -f  /home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/docker-peer0org2.yaml up -d; docker ps"

.PHONY: peer0org2-down
peer0org2-down:
	@ssh root@45.77.200.129 "docker-compose -f  /home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/docker-peer0org2.yaml down; docker ps"
.PHONY: peer0org2-clean
peer0org2-clean:
	@ssh root@45.77.200.129  "docker volume prune -f ; docker network prune -f ; docker rm -f -v `docker ps -a --no-trunc | grep "mycc" | cut -d ' ' -f 1` 2>/dev/null || true ; docker rmi `docker images --no-trunc | grep "mycc" | cut -d ' ' -f 1` 2>/dev/null || true; docker ps"
.PHONY: peer0org2-restart
peer0org2-restart: peer0org2-down peer0org1-up
