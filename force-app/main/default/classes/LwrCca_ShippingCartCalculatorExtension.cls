/**
 * @description       : This class extends CartExtension.ShippingCartCalculator provided by extension framework. It must
 *                      be registered in the Commerce Cloud Digital extension framework as a registered Service to be
 *                      invoked during cart calculation.
 *                      Main documentation source: https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/ShippingCartCalculator.html
 * @author            : Tom Zarr
 * @group             : Salesforce Commerce Partner Delivery Success (2026)
 * @last modified on  : 01-24-2026
 * @last modified by  : Tom Zarr
**/
public class LwrCca_ShippingCartCalculatorExtension extends CartExtension.ShippingCartCalculator {

    public LwrCca_ShippingCartCalculatorExtension() { }

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();

        for (Integer i = (cartValidationOutputList.size() - 1); i >= 0; i--) {
            CartExtension.CartValidationOutput cvo = cartValidationOutputList.get(i);
            if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.SHIPPING) {
                cartValidationOutputList.remove(cvo);
            }
        }

        CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();

        if (cartDeliveryGroups.size() == 0) {
            // setErrorInCart(cart, Label.No_Cart_Delivery_Group);
            setErrorInCart(cart, 'No_Cart_Delivery_Group');
        } else {
            CartExtension.CartItemList cartItems = cart.getCartItems();
            Integer numberOfUniqueItems = cartItems.size();
            for (Integer i = (cartDeliveryGroups.size() - 1); i >= 0; i--) {
                CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(i);
                CartExtension.CartDeliveryGroupMethodList cartDeliveryGroupMethods = cartDeliveryGroup.getCartDeliveryGroupMethods();
                // Clean up the CartDeliveryGroupMethods
                for (Integer j = (cartDeliveryGroupMethods.size() - 1); j >= 0; j--) {
                    CartExtension.CartDeliveryGroupMethod method = cartDeliveryGroupMethods.get(j);
                    cartDeliveryGroupMethods.remove(method);
                }
                // To clear selected Cart Delivery Group Method
                cartDeliveryGroup.setSelectedCartDeliveryGroupMethod(null);
                System.debug('CartData  '+ cart);
                System.debug('Cart WebstoreId  '+ cart.getWebstoreId()); 
                Product2 shippingProduct = getShippingProduct();
                if (shippingProduct == null) {
                    //setErrorInCart(cart, Label.No_Shipping_Products_Configured);
                    setErrorInCart(cart, 'No_Shipping_Products_Configured');
                } else {
                    String shippingProductId = Id.valueOf(shippingProduct.Id);
                    List<LwrCca_ShippingMetaData> shippingMetaDataDTOs = getMetaData(
                    cart.getWebstoreId()
                    );

                    System.debug('ShippingMEtdaDataList  '+ shippingMetaDataDTOs);
                    LwrCca_ShippingProviderRequest shippingRequest = createShippingRequest(cartDeliveryGroup);
                    System.debug('ShippingRequest '+ shippingRequest);
                    Boolean errorInResponse = true;
                    for (LwrCca_ShippingMetaData shippingMetaData : shippingMetaDataDTOs) {
                    shippingRequest.shippingMetaData = shippingMetaData;
                    LwrCca_AbstractShippingProvider sProvider = LwrCca_ShippingProviderFactory.getShippingProvider(shippingMetaData);
                    if (sProvider != null) {
                        shippingRequest.cartId = cart.getId();
                        Map<String, LwrCca_ShippingProviderResponse> shippingMethodsWithRate = sProvider.retrieveShippingRates(shippingRequest);
                        System.debug('ShippingMethodsWithRate'+ shippingMethodsWithRate);
                        if (shippingMethodsWithRate != null && shippingMethodsWithRate.size() > 0) {
                        setShippingOptionsInCart(shippingMethodsWithRate,cartDeliveryGroupMethods,shippingProductId,shippingMetaData);
                        errorInResponse = false;
                        }
                    }
                    }
                    if (errorInResponse) {
                        // setErrorInCart(cart, Label.Failed_to_get_shipping_options);
                        setErrorInCart(cart, 'Failed_to_get_shipping_options');
                    }
                }
            }
        }
    }

    @testVisible
    private virtual void setShippingOptionsInCart(Map<String, LwrCca_ShippingProviderResponse> shippingMethodsWithRate,
        CartExtension.CartDeliveryGroupMethodList cartDeliveryGroupMethods, String shippingProduct,
        LwrCca_ShippingMetaData shippingMetaData)
    {
        try {
            Map<String, String> shippingMethodNames;

            if (shippingMetaData.shippinggMethodNames != null) {
                shippingMethodNames = (Map<String, String>) JSON.deserialize(shippingMetaData.shippinggMethodNames,Map<String, String>.class);
            }

            for (String serviceCode : shippingMethodsWithRate.keySet()) {
                CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartExtension.CartDeliveryGroupMethod(
                shippingMethodNames != null ? shippingMethodNames.get(serviceCode): serviceCode,shippingMethodsWithRate.get(serviceCode).cost,shippingProduct);
                cartDeliveryGroupMethod.setExternalProvider(serviceCode);
                // cartDeliveryGroupMethod.setClassOfService(
                //   shippingMethodNames != null ? shippingMethodNames.get(serviceCode) : serviceCode
                // );
                if (shippingMethodsWithRate.get(serviceCode).carrier != null) {
                    cartDeliveryGroupMethod.setCarrier(shippingMethodsWithRate.get(serviceCode).carrier);
                }
                if (shippingMethodsWithRate.get(serviceCode).displayOrder != null) {
                    cartDeliveryGroupMethod.setClassOfService(String.valueOf(shippingMethodsWithRate.get(serviceCode).displayOrder
                    )
                    );
                }
                // if(shippingMethodsWithRate.get(serviceCode).displayOrder != null){
                //   cartDeliveryGroupMethod.setCustomField('Display_Order__c',shippingMethodsWithRate.get(serviceCode).displayOrder);
                // }

                cartDeliveryGroupMethod.setIsActive(true);
                cartDeliveryGroupMethods.add(cartDeliveryGroupMethod);
            }
        } catch (Exception expObj) { System.debug('Exception due to error ====' + expObj.getMessage() + 'at Line Number ====' +
                expObj.getLineNumber()
            );
            // WK_Exception.log(expObj, applicationName, moduleName, className,
            // methodName, supportData);
        }
    }

    private virtual void setErrorInCart(CartExtension.Cart cart,String errorMessage) {
        CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(CartExtension.CartValidationOutputTypeEnum.SHIPPING,CartExtension.CartValidationOutputLevelEnum.ERROR);
        cvo.setMessage(errorMessage);
        CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();
        cartValidationOutputList.add(cvo);
    }

    public virtual List<LwrCca_ShippingMetaData> getMetaData(String webStoreId) {
        return LwrCca_ShippingDetails.getMetaDataDTO(webStoreId);
    }

    public virtual Product2 getShippingProduct() {
        Product2 shippingProduct;
        List<Product2> shippingProducts = [SELECT Id FROM Product2 WHERE product2.Family = 'Shipping' LIMIT 1];
        if (shippingProducts.size() > 0) {
            shippingProduct = shippingProducts[0];
        }
        return shippingProduct;
    }

    public virtual LwrCca_ShippingProviderRequest createShippingRequest(CartExtension.CartDeliveryGroup cartDeliveryGroup) {
        LwrCca_ShippingProviderRequest request = new LwrCca_ShippingProviderRequest();
        request.street = cartDeliveryGroup.getDeliverToAddress().Street;
        request.city = cartDeliveryGroup.getDeliverToAddress().City;
        request.state = cartDeliveryGroup.getDeliverToAddress().State;
        request.postalCode = cartDeliveryGroup.getDeliverToAddress().PostalCode;
        request.country = cartDeliveryGroup.getDeliverToAddress().Country;

        return request;
    }
}