require 'cfer/groups'

AZ = (0..3).map do |i|
  Fn::select(i, Fn::get_azs(AWS::region))
end

resource :Vpc, 'AWS::EC2::VPC' do
  cidr_block '172.42.0.0/16'

  enable_dns_support true
  enable_dns_hostnames true
  instance_tenancy 'default'

  tag :Name, AWS::stack_name
end

resource :DefaultIGW, 'AWS::EC2::InternetGateway' do
  tag :Name, AWS::stack_name
end

resource :VPCIGW, 'AWS::EC2::VPCGatewayAttachment' do
  vpc_id Fn::ref(:Vpc)
  internet_gateway_id Fn::ref(:DefaultIGW)
end

resource_group "IS::Net::AZ" do |args|
  resource :Subnet, 'AWS::EC2::Subnet' do
    availability_zone args[:AvailabilityZone]
    cidr_block args[:CidrBlock]
    vpc_id args[:VpcId]

    map_public_ip_on_launch args[:Public] || false

    tag :Name, Fn::join('-', [AWS::stack_name, @name])
  end

  resource :SRTA, 'AWS::EC2::SubnetRouteTableAssociation' do
    subnet_id ref("Subnet")
    route_table_id ref(:RouteTable)
  end

  resource :RouteTable, 'AWS::EC2::RouteTable' do
    vpc_id args[:VpcId]

    tag :Name, Fn::join('-', [AWS::stack_name, @name])
  end

  resource :DefaultRoute, 'AWS::EC2::Route', DependsOn: [:VPCIGW] do
    route_table_id ref(:RouteTable)
    gateway_id args[:Igw]
    destination_cidr_block '0.0.0.0/0'
  end

  output :Subnet, ref("Subnet")
end

(0..3).each do |i|
  resource "PublicAZ#{i}", "IS::Net::AZ" do
    availability_zone AZ[i]
    vpc_id Fn::ref(:Vpc)
    cidr_block "172.42.#{i}.0/24"
    igw Fn::ref(:DefaultIGW)

    properties Public: true
  end

  resource "PrivateAZ#{i}", "IS::Net::AZ" do
    availability_zone AZ[i]
    vpc_id Fn::ref(:Vpc)
    cidr_block "172.42.#{i + 10}.0/24"
    igw Fn::ref(:DefaultIGW)

    properties Public: false
  end
end

output :VpcID, Fn::ref(:Vpc)

