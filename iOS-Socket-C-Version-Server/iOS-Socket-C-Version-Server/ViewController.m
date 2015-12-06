//
//  ViewController.m
//  iOS-Socket-C-Version-Server
//
//  Created by huangyibiao on 15/12/6.
//  Copyright © 2015年 huangyibiao. All rights reserved.
//

#import "ViewController.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
//  [self tcpServer];
  [self udpServer];
}

- (void)tcpServer {
  // 第一步：创建socket
  int error = -1;
  
  // 创建socket套接字
  int serverSocketId = socket(AF_INET, SOCK_STREAM, 0);
  // 判断创建socket是否成功
  BOOL success = (serverSocketId != -1);
  
  // 第二步：绑定端口号
  if (success) {
    NSLog(@"server socket create success");
    // Socket address
    struct sockaddr_in addr;
    
    // 初始化全置为0
    memset(&addr, 0, sizeof(addr));
    
    // 指定socket地址长度
    addr.sin_len = sizeof(addr);
    
    // 指定网络协议，比如这里使用的是TCP/UDP则指定为AF_INET
    addr.sin_family = AF_INET;
    
    // 指定端口号
    addr.sin_port = htons(1024);
    
    // 指定监听的ip，指定为INADDR_ANY时，表示监听所有的ip
    addr.sin_addr.s_addr = INADDR_ANY;
    
    // 绑定套接字
    error = bind(serverSocketId, (const struct sockaddr *)&addr, sizeof(addr));
    success = (error == 0);
  }
  
  // 第三步：监听
  if (success) {
    NSLog(@"bind server socket success");
    error = listen(serverSocketId, 5);
    success = (error == 0);
  }
  
  if (success) {
    NSLog(@"listen server socket success");
    
    while (true) {
      // p2p
      struct sockaddr_in peerAddr;
      int peerSocketId;
      socklen_t addrLen = sizeof(peerAddr);
      
      // 第四步：等待客户端连接
      // 服务器端等待从编号为serverSocketId的Socket上接收客户连接请求
      peerSocketId = accept(serverSocketId, (struct sockaddr *)&peerAddr, &addrLen);
      success = (peerSocketId != -1);
      
      if (success) {
        NSLog(@"accept server socket success,remote address:%s,port:%d",
              inet_ntoa(peerAddr.sin_addr),
              ntohs(peerAddr.sin_port));
        char buf[1024];
        size_t len = sizeof(buf);
        
        // 第五步：接收来自客户端的信息
        // 当客户端输入exit时才退出
        do {
          // 接收来自客户端的信息
          recv(peerSocketId, buf, len, 0);
          if (strlen(buf) != 0) {
            NSString *str = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
            if (str.length >= 1) {
              NSLog(@"received message from client：%@",str);
            }
          }
        } while (strcmp(buf, "exit") != 0);
        
        NSLog(@"收到exit信号，本次socket通信完毕");
        
        // 第六步：关闭socket
        close(peerSocketId);
      }
    }
  }
}

- (void)udpServer {
  int serverSockerId = -1;
  ssize_t len = -1;
  socklen_t addrlen;
  char buff[1024];
  struct sockaddr_in ser_addr;
  
  // 第一步：创建socket
  // 注意，第二个参数是SOCK_DGRAM，因为udp是数据报格式的
  serverSockerId = socket(AF_INET, SOCK_DGRAM, 0);
  
  if(serverSockerId < 0) {
    NSLog(@"Create server socket fail");
    return;
  }
  
  addrlen = sizeof(struct sockaddr_in);
  bzero(&ser_addr, addrlen);
  
  ser_addr.sin_family = AF_INET;
  ser_addr.sin_addr.s_addr = htonl(INADDR_ANY);
  ser_addr.sin_port = htons(1024);
  
  // 第二步：绑定端口号
  if(bind(serverSockerId, (struct sockaddr *)&ser_addr, addrlen) < 0) {
    NSLog(@"server connect socket fail");
    return;
  }
  
  do {
    bzero(buff, sizeof(buff));
    
    // 第三步：接收客户端的消息
    len = recvfrom(serverSockerId, buff, sizeof(buff), 0, (struct sockaddr *)&ser_addr, &addrlen);
    // 显示client端的网络地址
    NSLog(@"receive from %s\n", inet_ntoa(ser_addr.sin_addr));
    // 显示客户端发来的字符串
    NSLog(@"recevce:%s", buff);
    
    // 第四步：将接收到的客户端发来的消息，发回客户端
    // 将字串返回给client端
    sendto(serverSockerId, buff, len, 0, (struct sockaddr *)&ser_addr, addrlen);
  } while (strcmp(buff, "exit") != 0);
  
  // 第五步：关闭socket
  close(serverSockerId);
}

@end
