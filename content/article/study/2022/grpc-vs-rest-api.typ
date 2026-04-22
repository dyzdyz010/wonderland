#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "gRPC与REST API对比",
  desc: [REST API REST (Representational State Transfer) API],
  date: "2022-12-30",
  tags: (
    blog-tags.server,
    blog-tags.software,
    blog-tags.protobuf,
    blog-tags.programming,
  ),
)

= REST API

REST (Representational State Transfer) API 是一种用于交互式计算机系统的软件架构风格。它是基于 HTTP 协议，提供了一组标准的操作，可以让客户端与服务端进行交互。

常用的 REST API 操作包括：

- GET：获取资源
- POST：创建资源
- PUT：更新资源
- DELETE：删除资源

例如，我们可以使用 REST API 实现一个用于管理用户信息的服务。我们可以用 GET 操作来获取某个用户的信息，用 POST 操作来创建新用户，用 PUT 操作来更新用户信息，用 DELETE 操作来删除用户。

使用 REST API 的优点在于，它是基于 HTTP 协议的，所以可以被任何 HTTP 客户端调用，这也使得 REST API 成为了最常见的接口风格。同时，REST API 也支持跨语言调用，因为它是通过 HTTP 协议进行通信的。

然而，使用 REST API 也有一些限制。由于 REST API 使用 HTTP 协议，所以性能一般比较低，尤其是在大量的数据传输的情况下。同时，REST API 的调用也需要我们了解 HTTP 协议的知识。

= gRPC

gRPC（gRPC Remote Procedure Calls）是一种远程过程调用（RPC）框架，用于在分布式系统中进行跨语言通信。它基于 HTTP/2 协议，使用 Protocol Buffers（简称 Protobuf）作为消息序列化方式，支持 TLS 认证和加密。gRPC 主要应用于大量双向通信的应用场景，如服务器、客户端、移动端之间的通信。

在 gRPC 中，服务端和客户端都需要定义一个接口，接口中定义了要调用的方法以及传输的数据类型。在 gRPC 中，一个服务由多个方法组成，每个方法包含一个请求和一个响应，可以是单一请求/响应模式，也可以是服务端流式、客户端流式、双向流式模式。

与 REST API 相比，gRPC 有如下优势：

- 性能优越：gRPC 基于 HTTP/2 协议，支持多路复用，性能优越。
- 轻量：Protocol Buffers 是一种轻量的编码格式，比 JSON 和 XML 更小。
- 简单：gRPC 接口定义简单，代码生成工具会为你生成客户端和服务端的代码。

但是，gRPC 也有一些缺点：

- 不够通用：gRPC 使用 Protocol Buffers 作为消息序列化方式，对于非支持 Protocol Buffers 的语言，可能需要使用第三方库或者框架才能使用 gRPC。
- 不支持跨语言调用：gRPC 本身只支持跨语言调用，但是在实际使用中，由于消息序列化方式的不同，可能会出现跨语言调用的问题。

下面是一个使用 gRPC 进行跨语言通信的例子：

服务端使用 Go 语言实现：

```go
type helloServiceServer struct{}

func (s *helloServiceServer) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloResponse, error) {
	return &pb.HelloResponse{Message: "Hello " + in.Name}, nil
}

func main() {
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterHelloServiceServer(s, &helloServiceServer{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
```

客户端使用 Python 语言实现：

```python
def run():
    with grpc.insecure_channel('localhost:50051') as channel:
        stub = pb.HelloServiceStub(channel)
        response = stub.SayHello(pb.HelloRequest(name='world'))
    print("Greeter client received: " + response.message)

if __name__ == '__main__':
    run()
```

使用 gRPC，我们可以轻松地进行跨语言的通信。

与 REST API 相比，gRPC 具有更高的性能和更低的网络开销。同时，gRPC 还支持流式通信，可以大大减少服务端和客户端之间的通信次数。

但是，gRPC 的使用并不是所有场景都适用，当我们需要跨语言调用时，可能会受到 Protocol Buffers 的限制。同时，gRPC 的使用也需要我们了解 HTTP/2 和 Protocol Buffers 的知识。
