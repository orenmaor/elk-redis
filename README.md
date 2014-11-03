# A complete ELK stack on [AWS OpsWorks](http://aws.amazon.com/opsworks/)

This is a bunch of cookbooks that will allow you to run a complete Logstash setup on a scalable 
[AWS OpsWorks](http://aws.amazon.com/opsworks/) stack. 

- Agents wil ship their logs to Redis and the Logstash server cluster uses it as an input source.
- An ElasticSearch/Kibana cluster layer (Amazon Linux) – All log messages are stored and indexed here.  Viewable on an Angular.js interface on top of ElasticSearch to search, graph etc.
- A LogStash cluster layer (Amazon Linux) – Takes the messages from the RabbitMQ fanout and puts them into ElasticSearch.


## EC2 Setup

Before diving into OpsWorks, you'll need to do a bit of setup in the *EC2* area of AWS.

#### Create VPC
You can run the attached CloudFormation script, or do the work manually(See Below):

Create a VPC with X Public Subnets and X Private Subnets.  Create X NATS and put them into the Public Subnet.  Create a VPN Server and put it in the Public Subnet.

Create an `All Internal Servers` security group for all servers in the Private Subnet 
```
TCP Port      Source
--------      ------
ALL TRAFFIC   sg-xxxxxxxx (ID of the OpenVPN Servers security group)
```

Create a `NAT Server Servers` security group that allows traffic between clients and the NATs
```
TCP Port      Source
--------      ------
ALL TRAFFIC   sg-xxxxxxxx (ID of the All Servers security group)
```

## Setting up Security Groups

Go to the **Security Groups** section (in the **VPC** area, not the regular **EC2** one).

Create an `ElasticSearch Servers` security group that allows ElasticSearch traffic between servers
```
TCP Port      Source
--------      ------
9200-9400     sg-xxxxxxxx (ID of this group - ElasticSearch Servers Security Group)
```

Create a `Kibana Load Balancer` security group that will allow web traffic to the Kibana dashboard.

```
TCP Port      Source
--------      ------
80 (HTTP)     0.0.0.0/0
```

Create a `Kibana Internal` security group that will allow web traffic to the Kibana dashboard from the Load Balancers

```
TCP Port      Source
--------      ------
80 (HTTP)     sg-xxxxxxx (ID of the Kibana Load Balancer Security Group)
```


#### Create Elasticsearch Load Balancer

Next, we want to be able to put an ELB in front of our Elasticsearch array. We'll create an ELB in our VPC; Kibana will be accessible from the outside, and Logstash instances will be able to talk to it.

In the EC2 dashboard, create a new ELB
```
Load Balancer Name: <name>
```

**Listener Configuration:**
```
HTTP 80 -> HTTP 80
```
**Configuration Options:**
```
Ping Protocol: HTTP
Ping Port: 80
Ping Path: /
```
**Selected Subnets:**

* select all of the subnets you created in your VPC

**Security Groups:**
```
Security Group ID: sg-xxxxxxxxx (Kibana Load Balancer)
```

## SQS Setup

If you're planning on using Amazon's SQS as a "broker" between log producers and Elasticsearch, you'll need to configure a queue for this purpose and IAM users to read and write from the queue.

You can just use default values when creating a queue. Make a note of the ARN of your new queue.

### IAM Setup

Create IAM Roles and Instance Profiles. Also in IAM, create a Role called `logstash-elasticsearch-instance` with the policy below:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1393205558000",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```
### Stack Setup

On the OpsWorks dashboard, select "Add Stack". Most default values are fine (or you can change things like regions or availability zones to suit your needs), but make sure to set:

* **VPC** -> Select your VPC
* **Default operating system** -> Amazon Linux
* Under the "Advanced" settings:
 * **Chef version** -> 11.4
 * **User custom Chef cookbooks** -> Yes
 * **Repository URL** -> `URL you got this from`
 * **Custom Chef Json** -> See below

## Setting up your stack

- Use the following Chef custom JSON:

```json
{
 "chef_environment": "production",
    "elasticsearch": {
        "access_key" : "<IF IAM ROLE LEAVE BLANK OTHERWISE AWS KEY>",
        "secret_key" : "<IF IAM ROLE LEAVE BLANK OTHERWISE AWS SECRET KEY>",
        "region" : "<REPLACE WITH AWS REGION>"
    },
    "kibana": {
        "username": "<REPLACE WITH KIBANA USERNAME>",
        "password": "<REPLACE WITH KIBANA PASSWORD>"
    },
    "logstash": {
        "sqs_queue" : "<REPLACE ME NAME OF SQS QUEUE(NOT URL/ARN)>",
        "sqs_region" : "<REPLACE ME WITH SQS REGION>"
    },
    "redis": {
	"password" : "<REPLACE WITH REDIS PASSWORD>"
    }
}
```
### Configure Custom Chef recipes

#### ElasticSearch/Kibana

![elasticsearch/kibana recipes](https://s3.amazonaws.com/sturdy-github/orenmaor/elk/Recipe-ElasticSearch.png)

#### Logstash

![logstash recipes](https://s3.amazonaws.com/sturdy-github/orenmaor/elk/Recipe-Logstash-redis.png)

### Configure EBS Volumes - ElasticSearch/Kibana (Optional)

![elasticsearch/kibana ebs](https://s3.amazonaws.com/sturdy-github/orenmaor/elk/EBS-ElasticSearch.png)

### Configure ELB - ElasticSearch/Kibana 

![elasticsearch/kibana elb](https://s3.amazonaws.com/sturdy-github/orenmaor/elk/InternalLB-Kibana.png)

