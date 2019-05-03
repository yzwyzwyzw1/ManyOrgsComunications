# 声明

本程序采用真实solo多机多节点部署的方式，分别部署3台服务器，为了使得部署过程更加流畅，首先编写配置文件，以及makefile文件。在真实环境下部署时，首先需要修改将每个Readme文件，以及Makefile文件中的IP地址修改为真实的远程服务器的IP地址。


# 部署节点

1个orderer节点，4个peer节点（我仅仅部署了其中2个节点）。

节点名称   | IP Address  | Hostname                   | Org?    | Password
---        |---          | ---                        | ---     | ---
Orderer    |207.246.88.170 | orderer.example.com  | ——    | 2zL@Lrj1?!!muSN?
Peer0Org1  |45.63.14.242   | peer0.org1.example.com    | Org1    | 6e[K-qDJ7-q9tNwg
Peer0Org2  |45.77.200.129  | peer0.org2.example.com   | Org2     | $Dq3[Geh,b1=J{b+


部署peer节点的服务器要求内存大于或等于1G，否则在编译fabric时会报错。


# 生成配置文件

在本地生成组织结构与证书私钥文件
```bash
cryptogen generate  --config ./crypto-config.yaml  --output  crypto-config

mkdir channel-artifacts
export FABRIC_CFG_PATH=$PWD
export CHANNEL_NAME=mychannel
configtxgen  -profile TwoOrgsOrdererGenesis  -outputBlock     ./channel-artifacts/genesis.block
configtxgen  -profile TwoOrgsChannel -outputCreateChannelTx   ./channel-artifacts/mychannel.tx     -channelID $CHANNEL_NAME
configtxgen  -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

configtxgen  -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP

```

# 部署步骤

1. 创建每个节点，并对每个节点上的环境进行配置
2. 启动网络
3. 跨组织数据同步测试

# 启动网络开始测试

1.启动peer0org1节点：
```bash
make peer0org1-up

进入远程服务器
ssh root@45.63.14.242

docker logs peer0.org1.example.com

进入cli容器:
docker exec -it cli bash

peer channel create -o orderer.example.com:7050 -c mychannel -t 50s -f ./channel-artifacts/mychannel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer channel join -b mychannel.block
peer chaincode install -n mycc -p github.com/hyperledger/fabric/chaincode -v 1.0
peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n mycc -c '{"Args":["init","A","10","B","20"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" -v 1.0 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer chaincode query -C mychannel -n mycc -c '{"Args":["query","A"]}'
```
如果测试成功,正确的输出结果如下：
```bash
root@8f9990af6f2c:/opt/gopath/src/github.com/hyperledger/fabric/peer# peer chaincode query -C mychannel -n mycc -c '{"Args":["query","A"]}'
10
```

备份mychannel.block：

为了能够把该文件下复制到物理机的真实路径中，可以先退出cli容器，执行如下命令：
```bash
docker cp edd69eb89f93:/opt/gopath/src/github.com/hyperledger/fabric/peer/mychannel.block  /home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/channel-artifacts/
```

接下来我们可以将这个mychannel.block文件发送给peer0org2节点，使用如下命令：
```bash
scp ./channel-artifacts/mychannel.block root@45.77.200.129:/home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/channel-artifacts/
```
2.跨组织通信测试

```bash
启动peer0org2节点:
make peer0org2-up

进入远程服务器
ssh root@45.77.200.129

docker logs peer0.org2.example.com

首先将mychannel.block复制到cli容器中,其中cli容器ID需要使用docker ps命令查看
docker cp /home/gopath/src/github.com/hyperledgerFabricCluster/fixtures/channel-artifacts/mychannel.block  5131af251641:/opt/gopath/src/github.com/hyperledger/fabric/peer/  
```

在foo27org5节点上安装链码，并查询链码信息：
```bash
进入cli容器
docker exec -it cli bash

peer channel join -b mychannel.block

peer chaincode install -n mycc -p github.com/hyperledger/fabric/chaincode -v 1.0

peer chaincode query -C mychannel -n mycc -c '{"Args":["query","A"]}'

```
输出结果：
```bash
root@5131af251641:/opt/gopath/src/github.com/hyperledger/fabric/peer# peer chaincode query -C mychannel -n mycc -c '{"Args":["query","A"]}'
10
```
说明测试成功了！


3.继续测试，在peer0org1上执行调用合约
```bash
docker exec -it cli bash

peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","A","B","5"]}' -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer chaincode query -C mychannel -n mycc -c '{"Args":["query","A"]}'
```
输出结果：
```bash
5
```

在peer0org2上测试：
```bash
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","A"]}'
```
输出结果：
```bash
5
```
再次说明测试成功。

其他：

通道检查
```bash
peer channel list //查看通道
peer chaincode list --instantiated -C mychannel  //查看通道中被安装的链码
```
---
# 报错处理

报错1：

[root@zookeeper1 fixtures]# docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?

原因docker守护进程没有启动，解决办法，启动docker守护进程
```bash
systemctl start docker
```

报错2：
root@4e197ade526a:/opt/gopath/src/github.com/hyperledger/fabric/peer# peer channel list
Error: error getting endorser client for channel: endorser client failed to connect to peer0.org1.example.com:7051: failed to create new connection: connection error: desc = "transport: error while dialing: dial tcp 216.155.152.215:7051: connect: no route to host"

有虚拟机防火墙都关闭了,[参考网址](https://blog.csdn.net/ytangdigl/article/details/79796961):
```bash
systemctl stop firewalld.service
```
报错3：
Error: failed to create deliver client: orderer client failed to connect to orderer0.example.com:7050: failed to create new connection: context deadline exceeded

原因：orderer0.example.com节点网络没有启动。或者之前已经启动过了需要重新启动,也或者是- ORDERER_GENERAL_TLS_ENABLED设置成了false

报错4：
ERROR: Failed to Setup IP tables: Unable to enable SKIP DNAT rule:  (iptables failed: iptables --wait -t nat -I DOCKER -i br-2add1a39bc5d -j RETURN: iptables: No chain/target/match by that name.

原因是关闭防火墙之后docker需要重启，执行以下命令重启docker即可：
```bash
systemctl restart docker
```
报错5：
在cli中创建通道时报错
Error: got unexpected status: BAD_REQUEST -- error applying config update to existing channel 'mychannel': error authorizing update: error validating ReadSet: proposed update requires that key [Group]  /Channel/Application be at version 0, but it is currently at version 1

报错6：
Error: error endorsing chaincode: rpc error: code = Unknown desc = access denied: channel [mychannel] creator org [Org1MSP]
