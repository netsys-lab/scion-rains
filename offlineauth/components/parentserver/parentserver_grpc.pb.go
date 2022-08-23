// Code generated by protoc-gen-go-grpc. DO NOT EDIT.
// versions:
// - protoc-gen-go-grpc v1.2.0
// - protoc             v3.15.8
// source: parentserver.proto

package parentserver

import (
	context "context"
	grpc "google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
)

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
// Requires gRPC-Go v1.32.0 or later.
const _ = grpc.SupportPackageIsVersion7

// ParentServiceClient is the client API for ParentService service.
//
// For semantics around ctx use and closing/ending streaming RPCs, please refer to https://pkg.go.dev/google.golang.org/grpc/?tab=doc#ClientConn.NewStream.
type ParentServiceClient interface {
	InitDelegation(ctx context.Context, in *InitDelegationRequest, opts ...grpc.CallOption) (*InitDelegationResponse, error)
}

type parentServiceClient struct {
	cc grpc.ClientConnInterface
}

func NewParentServiceClient(cc grpc.ClientConnInterface) ParentServiceClient {
	return &parentServiceClient{cc}
}

func (c *parentServiceClient) InitDelegation(ctx context.Context, in *InitDelegationRequest, opts ...grpc.CallOption) (*InitDelegationResponse, error) {
	out := new(InitDelegationResponse)
	err := c.cc.Invoke(ctx, "/parentserver.ParentService/InitDelegation", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// ParentServiceServer is the server API for ParentService service.
// All implementations must embed UnimplementedParentServiceServer
// for forward compatibility
type ParentServiceServer interface {
	InitDelegation(context.Context, *InitDelegationRequest) (*InitDelegationResponse, error)
	mustEmbedUnimplementedParentServiceServer()
}

// UnimplementedParentServiceServer must be embedded to have forward compatible implementations.
type UnimplementedParentServiceServer struct {
}

func (UnimplementedParentServiceServer) InitDelegation(context.Context, *InitDelegationRequest) (*InitDelegationResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method InitDelegation not implemented")
}
func (UnimplementedParentServiceServer) mustEmbedUnimplementedParentServiceServer() {}

// UnsafeParentServiceServer may be embedded to opt out of forward compatibility for this service.
// Use of this interface is not recommended, as added methods to ParentServiceServer will
// result in compilation errors.
type UnsafeParentServiceServer interface {
	mustEmbedUnimplementedParentServiceServer()
}

func RegisterParentServiceServer(s grpc.ServiceRegistrar, srv ParentServiceServer) {
	s.RegisterService(&ParentService_ServiceDesc, srv)
}

func _ParentService_InitDelegation_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(InitDelegationRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(ParentServiceServer).InitDelegation(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/parentserver.ParentService/InitDelegation",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(ParentServiceServer).InitDelegation(ctx, req.(*InitDelegationRequest))
	}
	return interceptor(ctx, in, info, handler)
}

// ParentService_ServiceDesc is the grpc.ServiceDesc for ParentService service.
// It's only intended for direct use with grpc.RegisterService,
// and not to be introspected or modified (even as a copy)
var ParentService_ServiceDesc = grpc.ServiceDesc{
	ServiceName: "parentserver.ParentService",
	HandlerType: (*ParentServiceServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "InitDelegation",
			Handler:    _ParentService_InitDelegation_Handler,
		},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "parentserver.proto",
}