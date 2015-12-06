//
//  ViewController.m
//  iOS-Socket-C-Version-Client
//
//  Created by huangyibiao on 15/12/6.
//  Copyright © 2015年 huangyibiao. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#import <arpa/inet.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  
  //  [self tcpClient];
  [self udpClient];
}

- (void)tcpClient {
  // 第一步：创建soket
  // TCP是基于数据流的，因此参数二使用SOCK_STREAM
  int error = -1;
  int clientSocketId = socket(AF_INET, SOCK_STREAM, 0);
  BOOL success = (clientSocketId != -1);
  struct sockaddr_in addr;
  
  // 第二步：绑定端口号
  if (success) {
    NSLog(@"client socket create success");
    // 初始化
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    
    // 指定协议簇为AF_INET，比如TCP/UDP等
    addr.sin_family = AF_INET;
    
    // 监听任何ip地址
    addr.sin_addr.s_addr = INADDR_ANY;
    error = bind(clientSocketId, (const struct sockaddr *)&addr, sizeof(addr));
    success = (error == 0);
  }
  
  if (success) {
    // p2p
    struct sockaddr_in peerAddr;
    memset(&peerAddr, 0, sizeof(peerAddr));
    peerAddr.sin_len = sizeof(peerAddr);
    peerAddr.sin_family = AF_INET;
    peerAddr.sin_port = htons(1024);
    
    // 指定服务端的ip地址，测试时，修改成对应自己服务器的ip
    peerAddr.sin_addr.s_addr = inet_addr("192.168.1.107");
    
    socklen_t addrLen;
    addrLen = sizeof(peerAddr);
    NSLog(@"will be connecting");
    
    // 第三步：连接服务器
    error = connect(clientSocketId, (struct sockaddr *)&peerAddr, addrLen);
    success = (error == 0);
    
    if (success) {
      // 第四步：获取套接字信息
      error = getsockname(clientSocketId, (struct sockaddr *)&addr, &addrLen);
      success = (error == 0);
      
      if (success) {
        NSLog(@"client connect success, local address:%s,port:%d",
              inet_ntoa(addr.sin_addr),
              ntohs(addr.sin_port));
        
        // 这里只发送10次
        int count = 10;
        do {
          // 第五步：发送消息到服务端
          send(clientSocketId, "哈哈，server您好！", 1024, 0);
          count--;
          
          // 告诉server，客户端退出了
          if (count == 0) {
            send(clientSocketId, "exit", 1024, 0);
          }
        } while (count >= 1);
        
        // 第六步：关闭套接字
        close(clientSocketId);
      }
    } else {
      NSLog(@"connect failed");
      
      // 第六步：关闭套接字
      close(clientSocketId);
    }
  }
}

- (void)udpClient {
  int clientSocketId;
  ssize_t len;
  socklen_t addrlen;
  struct sockaddr_in client_sockaddr;
  char buffer[256] = "Hello, server, how are you?";
  
  // 第一步：创建Socket
  clientSocketId = socket(AF_INET, SOCK_DGRAM, 0);
  if(clientSocketId < 0) {
    NSLog(@"creat client socket fail\n");
    return;
  }
  
  addrlen = sizeof(struct sockaddr_in);
  bzero(&client_sockaddr, addrlen);
  client_sockaddr.sin_family = AF_INET;
  client_sockaddr.sin_addr.s_addr = inet_addr("192.168.1.107");
  client_sockaddr.sin_port = htons(1024);
  
  int count = 10;
  do {
    bzero(buffer, sizeof(buffer));
    sprintf(buffer, "%s", "Hello, server, how are you?");
    
    // 第二步：发送消息到服务端
    // 注意:UDP是面向无连接的，因此不用调用connect()
    // 将字符串传送给server端
   len = sendto(clientSocketId, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_sockaddr, addrlen);
    
    if (len > 0) {
      NSLog(@"发送成功");
    } else {
      NSLog(@"发送失败");
    }
    
    // 第三步：接收来自服务端返回的消息
    // 接收server端返回的字符串
    bzero(buffer, sizeof(buffer));
    len = recvfrom(clientSocketId, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_sockaddr, &addrlen);
    NSLog(@"receive message from server: %s", buffer);
    
    count--;
  } while (count >= 0);
  
  // 第四步：关闭socket
  // 由于是面向无连接的，消息发出处就可以了，不用管它收不收得到，发完就可以关闭了
  close(clientSocketId);
}

@end
