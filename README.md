# Explore UPS Shipping — Configure for B2B Commerce

A reference implementation of UPS shipping rate quoting for Salesforce B2B Commerce, based on the [Code-It-Forward](https://github.com/forcedotcom/commerce-extensibility) UPS solution. The integration uses the Salesforce Commerce Extension framework (introduced in Winter '24) to call the UPS Rating API via OAuth 2.0 named credentials and return real-time shipping options at checkout.

## What's in this repo

| Folder | Contents |
|---|---|
| `force-app/main/default/classes` | 23 Apex classes covering the shipping provider abstraction, UPS and internal flat-rate implementations, HTTP service layer, and all unit tests |
| `force-app/main/default/objects` | Custom metadata types (`HTTP_Service__mdt`, `Shipping_Provider__mdt`, `Internal_Shipping_Rate__mdt`), custom object (`ProductCodeShippingRate__c`), and the `Weight__c` field extension on `Product2` |
| `force-app/main/default/layouts` | Admin layouts for the two custom metadata types |
| `force-app/main/default/externalCredentials` | `UPSAuth` external credential (OAuth 2.0 Client Credentials flow against the UPS CIE token endpoint) |
| `force-app/main/default/namedCredentials` | `UPS Shipping` named credential pointing to `https://wwwcie.ups.com` |
| `data` | JSON examples for the `Request__c` and `Shipping_Options__c` fields on `Shipping_Provider__mdt` records |
| `docs` | Original Code-It-Forward PDFs and the upstream README |

## Prerequisites

- Salesforce CLI (`sf`) installed and up to date
- A published B2B Store in the target org
- A UPS developer test account — sign up at [developer.ups.com](https://developer.ups.com/get-started)
- `Product2.Family = 'Shipping'` product record in the org (used as the shipping line-item product)

## Deployment order

Deploy source folders in this order to avoid dependency errors:

1. `objects`
2. `layouts`
3. `externalCredentials/UPSAuth.externalCredential-meta.xml`
4. `namedCredentials/UPSShipping.namedCredential-meta.xml`
5. `classes`

## Activity guide

Step-by-step setup instructions, including custom metadata configuration, credential setup, and storefront verification, are in the accompanying activity guide: **https://sfdc.co/explore-ups-shipping**

## Additional documentation

- [Shipping Integration (using OAuth)](./docs/1.SF-LWR_Extension_Framework_Shipping_Integration_(using_OAuth)-010724-224833.pdf)
- [UPS Shipping Integration](./docs/2.SF-LWR_Extension_Framework_UPS_Shipping_Integration-010724-225710.pdf)
- [Flat Shipping Rates](./docs/3.SF-LWR_Extension_Framework_Flat_Shipping_Rates-010724-230330.pdf)

> ⚠️ This sample code is for demonstration and enablement purposes. Review and test thoroughly before using in a production org.
