package test

import (
    "testing"
    "strings"

    "fmt"
    "math/rand"
    "time"

    "github.com/aws/aws-sdk-go/aws"
    "github.com/aws/aws-sdk-go/aws/session"
    "github.com/aws/aws-sdk-go/service/autoscaling"
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

// This is main testing function that validates the EC2 ASG setup.
func TestEc2(t *testing.T) {
    t.Parallel()

    // Random name generator for avoiding conflicts
    rand.Seed(time.Now().UnixNano())

    randomInt1 := rand.Intn(90000)
    randomInt2 := rand.Intn(90000)
    if randomInt1 == randomInt2 {
        randomInt2 = (randomInt2 + 1000) % 90000  // To ensure no nonsense!
    }

    prefix := "ec2-runner-go-"

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
        TerraformDir: "../examples/ec2",
        Vars: map[string]interface{}{
            "project_name": randomName1,
            "project_name_2": randomName2,
            "vpc_cidr_block": "114.0.0.0/24",
            "gitlab_runner_token": gitlabRunnerToken,
            "tags": tags,
        },
    }

    // Destroy the resources after tests are completed
    defer terraform.Destroy(t, options)

    // Spin up the resources
    terraform.InitAndApply(t, options)

    // Retrieve the ASG name from Terraform output and assert that all instances are in service.
    asgName := terraform.Output(t, options, "asg_name")
    assertASGInstancesInService(t, asgName, "us-east-1")
}

// This function validates that all instances within the specified ASG are in service.
func assertASGInstancesInService(t *testing.T, asgName, region string) {
    sess, err := session.NewSession(&aws.Config{
        Region: aws.String(region),
    })

    if err != nil {
        t.Fatal(err)
    }

    svc := autoscaling.New(sess)

    input := &autoscaling.DescribeAutoScalingGroupsInput{
        AutoScalingGroupNames: []*string{
            aws.String(asgName),
        },
    }

    result, err := svc.DescribeAutoScalingGroups(input)
    if err != nil {
        t.Fatal(err)
    }

    // Validation checks!
    if len(result.AutoScalingGroups) > 0 && len(result.AutoScalingGroups[0].Instances) > 0 {
        for _, instance := range result.AutoScalingGroups[0].Instances {
            assert.Equal(t, strings.ToUpper("InService"), strings.ToUpper(*instance.LifecycleState))
        }
    } else {
        t.Fatal("No instances found in the ASG or ASG not found.")
    }
}
