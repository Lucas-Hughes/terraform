package test

import (
    "testing"
    "fmt"
    "math/rand"
    "time"
	"encoding/json"

    "github.com/aws/aws-sdk-go/aws"
    "github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/eks"
    "github.com/aws/aws-sdk-go/service/ssm"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

// This function retrieves the GitLab runner token from AWS SSM so we don't have to worry about retreiving
func getGitlabRunnerTokenFromSSM(ssmParameterName, region string) (string, error) {
    sess, err := session.NewSession(&aws.Config{
        Region: aws.String(region),
    })

    if err != nil {
        return "", err
    }

    svc := ssm.New(sess)
    param, err := svc.GetParameter(&ssm.GetParameterInput{
        Name:           aws.String(ssmParameterName),
        WithDecryption: aws.Bool(true),
    })

    if err != nil {
        return "", err
    }

    return *param.Parameter.Value, nil
}

// This is main testing function that validates the EKS ASG setup.
func TestEks(t *testing.T) {
    t.Parallel()

    // Random name generator for avoiding conflicts
    rand.Seed(time.Now().UnixNano())

    randomInt1 := rand.Intn(90000)
    randomInt2 := rand.Intn(90000)
    if randomInt1 == randomInt2 {
        randomInt2 = (randomInt2 + 1000) % 90000  // To ensure no nonsense!
    }

    prefix := "eks-runner-go-"

    randomName1 := fmt.Sprintf("%s%d", prefix, randomInt1)
    randomName2 := fmt.Sprintf("%s%d", prefix, randomInt2)

    region := "us-east-1"
    ssmParameterName := "/forge/terratest/gitlab-runner-token"

    gitlabRunnerToken, err := getGitlabRunnerTokenFromSSM(ssmParameterName, region)
    if err != nil {
        t.Fatal(err)
    }

    tags := map[string]string{
        "t_AppID": "SVC03377",
        "t_dcl":   "3",
        "Owner":   "lucas.j.hughes@outlook.com",
    }

    options := &terraform.Options{
        TerraformDir: "../examples/eks",
        Vars: map[string]interface{}{
            "project_name": randomName1,
            "project_name_2": randomName2,
            "vpc_cidr_block": "119.0.0.0/24",
            "gitlab_runner_token": gitlabRunnerToken,
            "tags": tags,
        },
    }

	// Ensure all resources are destroyed after test completion
	defer func() {
		if r := recover(); r != nil {
			terraform.Destroy(t, options)
			t.Fail()
		} else {
			terraform.Destroy(t, options)
		}
	}()

    // Spin up the resources
    terraform.InitAndApply(t, options)

    // Retrieve the cluster name and self-managed node groups from Terraform output.
    clusterName := terraform.Output(t, options, "cluster_name")
    selfManagedNodeGroups := terraform.Output(t, options, "self_managed_node_groups")

    // Here, you can add the assert or any other validation logic to check the retrieved outputs.
    assert.NotNil(t, clusterName, "Cluster name should not be nil")
    assert.NotNil(t, selfManagedNodeGroups, "Self Managed Node Groups should not be nil")

    assertEksCluster(t, clusterName, region)
    assertSelfManagedNodeGroups(t, clusterName, selfManagedNodeGroups, region) 
}

// This function is ensuring that the EKS cluster spins up to be ACTIVE
func assertEksCluster(t *testing.T, clusterName, region string) {
	assert.NotNil(t, clusterName, "Failed: Cluster name is nil")

    sess, err := session.NewSession(&aws.Config{
        Region: aws.String(region),
    })
    
    if err != nil {
        t.Fatal(err)
    }

    svc := eks.New(sess)

    input := &eks.DescribeClusterInput{
        Name: aws.String(clusterName),
    }

    result, err := svc.DescribeCluster(input)
    if err != nil {
        t.Fatal(err)
    }

    assert.Equal(t, "ACTIVE", *result.Cluster.Status, "EKS Cluster should be ACTIVE")
}

// This function validates that the self-managed node groups are correctly set up.
func assertSelfManagedNodeGroups(t *testing.T, clusterName, selfManagedNodeGroups, region string) {
    // For simplicity, assuming selfManagedNodeGroups is a JSON string containing node group ARNs or names
    // Adjust the logic below to fit the actual format of your selfManagedNodeGroups output

    var nodeGroupNames []string // or ARNs if applicable
    err := json.Unmarshal([]byte(selfManagedNodeGroups), &nodeGroupNames)
    if err != nil {
        t.Fatal(err)
    }

    assert.NotEmpty(t, nodeGroupNames, "Node groups should not be empty")

    sess, err := session.NewSession(&aws.Config{
        Region: aws.String(region),
    })
    
    if err != nil {
        t.Fatal(err)
    }

    svc := eks.New(sess)

    for _, ngName := range nodeGroupNames {
        input := &eks.DescribeNodegroupInput{
            ClusterName:   aws.String(clusterName), // Replace with actual cluster name variable or value
            NodegroupName: aws.String(ngName),
        }

        result, err := svc.DescribeNodegroup(input)
        if err != nil {
            t.Fatal(err)
        }

        // Adjust the expected status according to your needs
        assert.Equal(t, "ACTIVE", *result.Nodegroup.Status, "Node group should be ACTIVE")
    }
}