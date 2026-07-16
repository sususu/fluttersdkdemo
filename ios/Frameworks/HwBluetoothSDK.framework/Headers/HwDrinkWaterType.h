//
//  HwDrinkWaterType.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwDrinkWaterType) {
    HwDrinkWaterTypeWater = 0x00,
    HwDrinkWaterTypeCoffee = 0x01,
    HwDrinkWaterTypeMilk = 0x02,
    HwDrinkWaterTypeTea = 0x03,
    HwDrinkWaterTypeJuice = 0x04,
    HwDrinkWaterTypeCoconutWater = 0x05,
    HwDrinkWaterTypeCarbonatedDrink = 0x06,
    HwDrinkWaterTypeButtermilk = 0x07,
    HwDrinkWaterTypeLassi = 0x08,
    HwDrinkWaterTypeProteinShake = 0x09,
    HwDrinkWaterTypeLemonWater = 0x0a,
    HwDrinkWaterTypeMilkshake = 0x0b,
    HwDrinkWaterTypeElectrolyte = 0x0c,
    HwDrinkWaterTypeOther = 0x0d,
    HwDrinkWaterTypeCocktail = 0x0e,
    HwDrinkWaterTypeBeer = 0x0f,
    HwDrinkWaterTypeUnknown = 0xff,
};

NS_ASSUME_NONNULL_END
