//
//  HwAiAgent.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2025/9/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, HwAiAgentType) {
    // 健康相关
    HwAiAgentTypeHealthyDietRecommendation = 0x80,
    HwAiAgentTypeExerciseHealthAssistant = 0x81,
    HwAiAgentTypeBloodSugarHealth = 0x82,
    HwAiAgentTypePsychologicalConsultant = 0x83,
    HwAiAgentTypePersonalChef = 0x84,
    HwAiAgentTypeTravelPlanningExpert = 0x85,
    HwAiAgentTypeFoodCalorieQuery = 0x86,
    HwAiAgentTypeRunningMethods = 0x87,
    
    // 文案创作
    HwAiAgentTypeCopywriterGenerator = 0x88,
    HwAiAgentTypePASSalesCopy = 0x8b,
    HwAiAgentTypeAdMadman = 0x8c,
    HwAiAgentTypeWeeklyReportGenerator = 0x8d,
    
    // 娱乐休闲
    HwAiAgentTypeAstrologer = 0x89,
    HwAiAgentTypeHoroscope = 0x8e,
    HwAiAgentTypeWhatToEatToday = 0x8f,
    HwAiAgentTypeRapper = 0x90,
    HwAiAgentTypeJokeTeller = 0x91,
    HwAiAgentTypeMockMaster = 0x92,
    HwAiAgentTypeAnswerBook = 0x93,
    HwAiAgentTypeDigitalBomb = 0x94,

    // 生活服务
    HwAiAgentTypeColorCoordinator = 0x95,
    HwAiAgentTypeDreamInterpreter = 0x96,
    HwAiAgentTypeHealthExpert = 0x97,
    HwAiAgentTypeSkincareEncyclopedia = 0x98,
    HwAiAgentTypeLifeHacks = 0x99,
    HwAiAgentTypePetHealthConsultant = 0x9a,
    HwAiAgentTypeTranslator = 0x9b,
    HwAiAgentTypeWeatherForecast = 0x9c,

    // 人际沟通
    HwAiAgentTypeHighEQReply = 0x9d,
    HwAiAgentTypeMBTIExpert = 0x9e,
    HwAiAgentTypeCareerPlanning = 0x9f,

    // 办公工具
    HwAiAgentTypeDataAnalysis = 0xa0,
    HwAiAgentTypePptMaker = 0xa1,
    HwAiAgentTypeMovieExplanation = 0xa2,
    HwAiAgentTypeCreativeGenerator = 0xa3,
    HwAiAgentTypeDailyQuote = 0xa4,
    HwAiAgentTypeAIBookReader = 0xa5,
    HwAiAgentTypeSWOTExpert = 0xa6,

    // 个人发展
    HwAiAgentTypeMemoryTraining = 0xa7,
    HwAiAgentTypeSleepManager = 0xa8,
    HwAiAgentTypePartyGames = 0xa9,
    HwAiAgentTypeGiftRecommendation = 0xaa,
    HwAiAgentTypeProgrammingGuide = 0xab,

    // 知识百科
    HwAiAgentTypeFlowerLanguage = 0xac,
    HwAiAgentTypePersonalColorAnalysis = 0xad,
    HwAiAgentTypeHandcraftExpert = 0xae,
    HwAiAgentTypeParentingKnowledge = 0xaf,
    HwAiAgentTypeWorldRecords = 0xb0,
    HwAiAgentTypeBookLibrary = 0xb1,
    HwAiAgentTypeCarHome = 0xb2,
    HwAiAgentTypeGeographyKnowledge = 0xb3,
    HwAiAgentTypeScienceSpace = 0xb4,

    // 技术工具
    HwAiAgentTypeAITextExpansion = 0xb5,
    HwAiAgentTypeIQTest = 0xb6,

    // 情感社交
    HwAiAgentTypeDatingTips = 0xb7,
    HwAiAgentTypeBrainTeasers = 0xb8,

    // 思维训练
    HwAiAgentTypeThinkingTraining = 0xb9,
    HwAiAgentTypeChatCompanion = 0xba,
    HwAiAgentTypeProbabilityCalculation = 0xbb,
    HwAiAgentTypeBMICalculator = 0x8a
};
@interface HwAiAgent : NSObject

@property(nonatomic, assign) HwAiAgentType type;
@property(nonatomic, assign) BOOL on;

@end

NS_ASSUME_NONNULL_END
