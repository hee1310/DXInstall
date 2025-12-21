#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// 定义DXSETUP实际返回的MSI标准退出码（核心是你指定的8个码）
typedef enum {
    DXSETUP_SUCCESS = 0,                // 成功
    DXSETUP_CANCEL_2 = 2,               // 用户取消（基础码）
    DXSETUP_PERMISSION_DENIED = 5,      // 权限不足
    DXSETUP_CANCEL_1602 = 1602,         // 用户取消（MSI码）
    DXSETUP_UNKNOWN_PRODUCT = 1605,     // 产品未安装
    DXSETUP_DUPLICATE_PRODUCT = 1638,   // 重复版本
    DXSETUP_REBOOT_INITIATED = 1641,    // 成功+已触发重启
    DXSETUP_REBOOT_REQUIRED = 3010      // 成功+需要手动重启
} DXSetupRealCode;

// 映射真实返回码到名称和官方含义
typedef struct {
    DXSetupRealCode code;
    const char* name;
    const char* description;
} DXSetupRealCodeInfo;

// 初始化真实返回码信息表（仅包含你指定的8个码）
DXSetupRealCodeInfo dxsetup_real_code_table[] = {
    {DXSETUP_SUCCESS, "SUCCESS", "ERROR_SUCCESS - 安装/操作成功完成"},
    {DXSETUP_CANCEL_2, "CANCEL_2", "用户手动取消安装（基础码）"},
    {DXSETUP_PERMISSION_DENIED, "PERMISSION_DENIED", "ERROR_ACCESS_DENIED - 权限不足（需要管理员）"},
    {DXSETUP_CANCEL_1602, "CANCEL_1602", "MSI_USERCANCEL - 用户取消安装（MSI专用码）"},
    {DXSETUP_UNKNOWN_PRODUCT, "UNKNOWN_PRODUCT", "MSI_UNKNOWNPRODUCT - 操作仅对已安装产品有效"},
    {DXSETUP_DUPLICATE_PRODUCT, "DUPLICATE_PRODUCT", "MSI_DUPLICATEPRODUCT - 已安装该产品的另一版本"},
    {DXSETUP_REBOOT_INITIATED, "REBOOT_INITIATED", "MSI_SUCCESS_REBOOTINITIATED - 安装成功，已触发重启"},
    {DXSETUP_REBOOT_REQUIRED, "REBOOT_REQUIRED", "ERROR_SUCCESS_REBOOT_REQUIRED - 操作成功，需要手动重启"}
};

// 校验返回码是否为指定的真实码，并获取含义
bool get_dxsetup_real_code_info(int code, DXSetupRealCodeInfo* info) {
    int table_size = sizeof(dxsetup_real_code_table) / sizeof(DXSetupRealCodeInfo);
    for (int i = 0; i < table_size; i++) {
        if (dxsetup_real_code_table[i].code == code) {
            *info = dxsetup_real_code_table[i];
            return true;
        }
    }
    return false;
}

// 通过名称（如SUCCESS）获取对应的真实返回码
int get_real_code_by_name(const char* name) {
    int table_size = sizeof(dxsetup_real_code_table) / sizeof(DXSetupRealCodeInfo);
    for (int i = 0; i < table_size; i++) {
        if (strcmp(dxsetup_real_code_table[i].name, name) == 0) {
            return dxsetup_real_code_table[i].code;
        }
    }
    return -1; // 无效名称
}

int main(int argc, char *argv[]) {
    // 默认返回码：0（成功，符合真实DXSETUP行为）
    int exit_code = DXSETUP_SUCCESS;
    DXSetupRealCodeInfo code_info;

    // 解析命令行参数：支持两种格式
    // 格式1: DXSETUP.exe -exitcode 3010
    // 格式2: DXSETUP.exe -exitcode REBOOT_REQUIRED
    if (argc == 3 && strcmp(argv[1], "-exitcode") == 0) {
        // 先尝试按名称解析（如REBOOT_REQUIRED）
        int code_from_name = get_real_code_by_name(argv[2]);
        if (code_from_name != -1) {
            exit_code = code_from_name;
        } else {
            // 按数字解析
            exit_code = atoi(argv[2]);
        }

        // 校验返回码是否为你指定的真实DXSETUP码
        if (!get_dxsetup_real_code_info(exit_code, &code_info)) {
            printf("错误：无效的DXSETUP返回码 %d\n", exit_code);
            printf("仅支持以下真实返回码：\n");
            // 打印所有合法码列表（方便参考）
            int table_size = sizeof(dxsetup_real_code_table) / sizeof(DXSetupRealCodeInfo);
            for (int i = 0; i < table_size; i++) {
                printf("  %d (%s): %s\n", 
                       dxsetup_real_code_table[i].code,
                       dxsetup_real_code_table[i].name,
                       dxsetup_real_code_table[i].description);
            }
            // 非法码重置为默认值（0）
            exit_code = DXSETUP_SUCCESS;
            printf("已自动重置为默认返回码：%d (SUCCESS)\n", exit_code);
        }
    }

    // 打印返回码详细信息（模拟执行提示）
    get_dxsetup_real_code_info(exit_code, &code_info);
    printf("==================== 虚假DXSETUP.exe ====================\n");
    printf("无实际DirectX安装操作，仅返回真实MSI退出码\n");
    printf("返回码数字：%d\n", exit_code);
    printf("返回码标识：%s\n", code_info.name);
    printf("官方含义：%s\n", code_info.description);
    printf("=========================================================\n");

    // 核心功能：返回指定的真实DXSETUP返回码
    return exit_code;
}