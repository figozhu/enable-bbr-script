#!/bin/bash

# BBR 控制脚本
# 从 x-ui.sh 提取的 BBR 相关功能
# 用于独立控制 BBR 的开启和关闭

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 确认函数
confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

# 检查系统信息
check_sys() {
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/alpine-release ]]; then
        release="alpine"
        systemPackage="apk"
    elif [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "alpine" /etc/issue; then
        release="alpine"
        systemPackage="apk"
    elif grep -Eqi "debian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "alpine" /proc/version; then
        release="alpine"
        systemPackage="apk"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# 检查 BBR 状态
check_bbr_status() {
    local param=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    if [[ x"${param}" == x"bbr" ]]; then
        return 0
    else
        return 1
    fi
}

# 检查是否为 Alpine 系统
is_alpine() {
    [[ -f /etc/alpine-release ]] || grep -qi "alpine" /etc/issue 2>/dev/null || grep -qi "alpine" /proc/version 2>/dev/null
}

# 检查内核模块是否可用
check_kernel_module() {
    local module=$1
    if [[ -f /proc/modules ]]; then
        grep -q "^${module}" /proc/modules 2>/dev/null
    else
        return 1
    fi
}

# 加载内核模块
load_kernel_module() {
    local module=$1
    if ! check_kernel_module "$module"; then
        echo -e "${yellow}正在尝试加载内核模块: $module${plain}"
        modprobe "$module" 2>/dev/null || {
            echo -e "${yellow}无法加载模块 $module，可能内核不支持${plain}"
            return 1
        }
    fi
    return 0
}

# Alpine 系统特殊的 BBR 启用方法
enable_bbr_alpine() {
    echo -e "${green}检测到 Alpine 系统，使用特殊配置方法${plain}"
    
    # 检查并加载必要的内核模块
    load_kernel_module "tcp_bbr"
    
    # 创建 sysctl 配置文件（如果不存在）
    if [[ ! -f /etc/sysctl.conf ]]; then
        touch /etc/sysctl.conf
    fi
    
    # 检查系统是否支持这些参数
    local qdisc_supported=true
    local bbr_supported=true
    
    # 测试 net.core.default_qdisc 参数
    if ! sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1; then
        echo -e "${yellow}警告: net.core.default_qdisc 参数不受支持，跳过此配置${plain}"
        qdisc_supported=false
    else
        # 如果支持，添加到配置文件
        if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        fi
    fi
    
    # 测试 BBR 拥塞控制
    if ! sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; then
        echo -e "${red}错误: 系统不支持 BBR 拥塞控制算法${plain}"
        return 1
    else
        # 如果支持，添加到配置文件
        if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        fi
    fi
    
    # 应用配置
    sysctl -p >/dev/null 2>&1
    
    # 验证 BBR 是否启用成功
    if check_bbr_status; then
        echo -e "${green}BBR 在 Alpine 系统上启用成功！${plain}"
        if [[ "$qdisc_supported" == "false" ]]; then
            echo -e "${yellow}注意: 队列调度算法配置被跳过，但 BBR 拥塞控制已启用${plain}"
        fi
        return 0
    else
        echo -e "${red}BBR 启用失败${plain}"
        return 1
    fi
}

# 安装 BBR
install_bbr() {
    if check_bbr_status; then
        echo -e "${green}BBR 已经启用！${plain}"
        return
    fi

    # 检查内核版本
    local kernel_version=$(uname -r | cut -d- -f1)
    local kernel_version_major=$(echo $kernel_version | cut -d. -f1)
    local kernel_version_minor=$(echo $kernel_version | cut -d. -f2)

    if [[ $kernel_version_major -gt 4 ]] || [[ $kernel_version_major -eq 4 && $kernel_version_minor -ge 9 ]]; then
        echo -e "${green}检测到内核版本 $kernel_version，支持 BBR${plain}"
    else
        echo -e "${red}当前内核版本 $kernel_version 不支持 BBR，需要升级内核到 4.9 或更高版本${plain}"
        return 1
    fi

    echo -e "${green}开始启用 BBR...${plain}"

    # 如果是 Alpine 系统，使用特殊方法
    if is_alpine; then
        enable_bbr_alpine
        return $?
    fi

    # 其他系统的标准方法
    # 修改系统配置
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    fi

    if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    fi

    # 应用配置
    sysctl -p

    # 验证 BBR 是否启用成功
    if check_bbr_status; then
        echo -e "${green}BBR 启用成功！${plain}"
    else
        echo -e "${red}BBR 启用失败，请检查系统配置${plain}"
        return 1
    fi
}

# Alpine 系统特殊的 BBR 禁用方法
disable_bbr_alpine() {
    echo -e "${green}检测到 Alpine 系统，使用特殊配置方法${plain}"
    
    # 从 sysctl.conf 中移除 BBR 配置
    sed -i '/net.core.default_qdisc=fq/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf

    # 尝试设置为 cubic（如果支持）
    if sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1; then
        echo "net.ipv4.tcp_congestion_control=cubic" >> /etc/sysctl.conf
        echo -e "${green}已设置拥塞控制算法为 cubic${plain}"
    else
        # 如果 cubic 不支持，尝试其他算法
        local available_cc=$(sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | cut -d= -f2 | tr ' ' '\n' | grep -v bbr | head -1)
        if [[ -n "$available_cc" ]]; then
            sysctl -w net.ipv4.tcp_congestion_control="$available_cc" >/dev/null 2>&1
            echo "net.ipv4.tcp_congestion_control=$available_cc" >> /etc/sysctl.conf
            echo -e "${green}已设置拥塞控制算法为 $available_cc${plain}"
        fi
    fi
    
    # 应用配置
    sysctl -p >/dev/null 2>&1
}

# 禁用 BBR
disable_bbr() {
    if ! check_bbr_status; then
        echo -e "${yellow}BBR 当前未启用${plain}"
        return
    fi

    echo -e "${yellow}开始禁用 BBR...${plain}"

    # 如果是 Alpine 系统，使用特殊方法
    if is_alpine; then
        disable_bbr_alpine
    else
        # 其他系统的标准方法
        # 从 sysctl.conf 中移除 BBR 配置
        sed -i '/net.core.default_qdisc=fq/d' /etc/sysctl.conf
        sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf

        # 设置为默认的拥塞控制算法
        echo "net.ipv4.tcp_congestion_control=cubic" >> /etc/sysctl.conf

        # 应用配置
        sysctl -p
    fi

    # 验证 BBR 是否禁用成功
    if ! check_bbr_status; then
        echo -e "${green}BBR 禁用成功！${plain}"
    else
        echo -e "${red}BBR 禁用失败，请手动检查配置${plain}"
        return 1
    fi
}

# 显示 BBR 状态
show_bbr_status() {
    echo -e "${green}=== BBR 状态信息 ===${plain}"
    
    # 显示系统信息
    if is_alpine; then
        echo -e "操作系统: ${green}Alpine Linux${plain}"
        if [[ -f /etc/alpine-release ]]; then
            local alpine_version=$(cat /etc/alpine-release)
            echo -e "Alpine 版本: ${green}$alpine_version${plain}"
        fi
    fi
    
    # 显示当前拥塞控制算法
    local current_cc=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
    if [[ -n "$current_cc" ]]; then
        echo -e "当前拥塞控制算法: ${green}$current_cc${plain}"
    else
        echo -e "当前拥塞控制算法: ${red}无法获取${plain}"
    fi
    
    # 显示可用的拥塞控制算法
    local available_cc=$(sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | cut -d= -f2)
    if [[ -n "$available_cc" ]]; then
        echo -e "可用拥塞控制算法:$available_cc"
    else
        echo -e "可用拥塞控制算法: ${red}无法获取${plain}"
    fi
    
    # 显示队列调度算法（Alpine 可能不支持）
    local qdisc=$(sysctl net.core.default_qdisc 2>/dev/null | awk '{print $3}')
    if [[ -n "$qdisc" ]]; then
        echo -e "默认队列调度算法: ${green}$qdisc${plain}"
    else
        echo -e "默认队列调度算法: ${yellow}不支持或无法获取${plain}"
    fi
    
    # BBR 状态
    if check_bbr_status; then
        echo -e "BBR 状态: ${green}已启用${plain}"
    else
        echo -e "BBR 状态: ${red}未启用${plain}"
    fi
    
    # 内核版本
    local kernel_version=$(uname -r)
    echo -e "内核版本: ${green}$kernel_version${plain}"
    
    # 检查内核模块状态（如果是 Alpine）
    if is_alpine; then
        echo -e "${green}=== Alpine 系统特殊信息 ===${plain}"
        if check_kernel_module "tcp_bbr"; then
            echo -e "BBR 内核模块: ${green}已加载${plain}"
        else
            echo -e "BBR 内核模块: ${yellow}未加载${plain}"
        fi
    fi
}

# 显示菜单
show_menu() {
    echo -e "
${green}BBR 控制脚本${plain}
${green}0.${plain} 退出脚本
————————————————
${green}1.${plain} 启用 BBR
${green}2.${plain} 禁用 BBR
${green}3.${plain} 查看 BBR 状态
————————————————
"
    echo && read -p "请输入选择 [0-3]: " num

    case "${num}" in
        0)
            exit 0
        ;;
        1)
            install_bbr
        ;;
        2)
            if confirm "确定要禁用 BBR 吗？这可能会影响网络性能"; then
                disable_bbr
            fi
        ;;
        3)
            show_bbr_status
        ;;
        *)
            echo -e "${red}请输入正确的数字 [0-3]${plain}"
        ;;
    esac
}

# 主函数
main() {
    # 检查是否为 root 用户
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red}错误：此脚本必须以 root 权限运行！${plain}"
        exit 1
    fi

    # 检查系统类型
    if ! check_sys sysRelease ubuntu && ! check_sys sysRelease debian && ! check_sys sysRelease centos && ! check_sys sysRelease alpine; then
        echo -e "${red}不支持的操作系统，请使用 Ubuntu、Debian、CentOS 或 Alpine Linux${plain}"
        exit 1
    fi

    # 如果有命令行参数，直接执行对应功能
    case "$1" in
        "enable"|"on")
            install_bbr
            exit 0
        ;;
        "disable"|"off")
            disable_bbr
            exit 0
        ;;
        "status"|"check")
            show_bbr_status
            exit 0
        ;;
        "help"|"-h"|"--help")
            echo -e "${green}BBR 控制脚本使用说明：${plain}"
            echo -e "  $0                 - 显示交互式菜单"
            echo -e "  $0 enable|on       - 启用 BBR"
            echo -e "  $0 disable|off     - 禁用 BBR"
            echo -e "  $0 status|check    - 查看 BBR 状态"
            echo -e "  $0 help|-h|--help  - 显示此帮助信息"
            exit 0
        ;;
        "")
            # 无参数时显示菜单
            while true; do
                show_menu
            done
        ;;
        *)
            echo -e "${red}未知参数: $1${plain}"
            echo -e "使用 $0 help 查看帮助信息"
            exit 1
        ;;
    esac
}

# 执行主函数
main "$@"
