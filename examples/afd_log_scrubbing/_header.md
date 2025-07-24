# Azure Front Door Log Scrubbing Example

This example demonstrates how to configure log scrubbing for an Azure Front Door profile using the Azure Verified Module (AVM) for CDN Profile.

Log scrubbing allows you to control what data gets removed or masked from access logs for compliance and privacy purposes. This is particularly useful for organizations that need to comply with data protection regulations like GDPR while maintaining operational visibility.

## Features Demonstrated

- Premium Azure Front Door profile with log scrubbing enabled
- Multiple scrubbing rules for different data types:
  - Request IP addresses
  - Query string argument names  
  - Request URIs
- Proper tagging for resource management

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Important Notes

- Log scrubbing is automatically **enabled** when one or more `scrubbing_rule` blocks are present
- Log scrubbing is automatically **disabled** when no `scrubbing_rule` blocks are defined
- Maximum of 3 scrubbing rules allowed per profile
- The operator is implicitly set to `EqualsAny` and cannot be changed
- Log scrubbing requires either Standard or Premium Azure Front Door SKU

## Compliance Benefits

This configuration helps organizations:
- Remove sensitive data from access logs
- Meet GDPR and other privacy regulation requirements
- Maintain operational visibility while protecting customer privacy
- Implement defense-in-depth security practices
