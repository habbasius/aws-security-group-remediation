import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    group_id = event['GroupId']
    response = ec2.describe_security_groups(GroupIds=[group_id])
    permissions = response['SecurityGroups'][0]['IpPermissions']

    to_revoke = []
    for perm in permissions:
        if perm.get('FromPort') == 22 and perm.get('ToPort') == 22 and perm.get('IpProtocol') == 'tcp':
            for ip_range in perm.get('IpRanges', []):
                if ip_range.get('CidrIp') == '0.0.0.0/0':
                    to_revoke.append({
                        'IpProtocol': 'tcp',
                        'FromPort': 22,
                        'ToPort': 22,
                        'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                    })

    if to_revoke:
        ec2.revoke_security_group_ingress(GroupId=group_id, IpPermissions=to_revoke)
        return {'status': 'revoked', 'group': group_id}
    else:
        return {'status': 'no action needed', 'group': group_id}
