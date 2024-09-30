#!/usr/bin/env bash
#Blog:https://www.moerats.com/

Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

# root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}Error:This script must be run as root!${Font}"
        exit 1
    fi
}

# 检测ovz
ovz_no(){
    if [[ -d "/proc/vz" ]]; then
        echo -e "${Red}Your VPS is based on OpenVZ，not supported!${Font}"
        exit 1
    fi
}

# 设置swap优先级
set_swap_priority(){
    echo -e "${Green}请输入swap优先级（数值越大优先级越高，建议范围0-32767）：${Font}"
    read -p "请输入优先级:" swappriority

    # 检查输入是否为有效的整数
    if ! [[ "$swappriority" =~ ^[0-9]+$ ]]; then
        echo -e "${Red}无效的优先级输入，请输入一个数字！${Font}"
        set_swap_priority
    elif [ "$swappriority" -lt 0 ] || [ "$swappriority" -gt 32767 ]; then
        echo -e "${Red}优先级必须在0到32767之间！${Font}"
        set_swap_priority
    fi
}

add_swap(){
    echo -e "${Green}请输入需要添加的swap，建议为内存的2倍！（以MB为单位）${Font}"
    read -p "请输入swap数值:" swapsize

    # 检查输入是否为有效的整数
    if ! [[ "$swapsize" =~ ^[0-9]+$ ]]; then
        echo -e "${Red}无效的swap大小输入，请输入一个数字！${Font}"
        add_swap
        return
    fi

    # 设置swap优先级
    set_swap_priority

    # 检查是否存在swapfile
    grep -q "swapfile" /etc/fstab

    # 如果不存在将为其创建swap
    if [ $? -ne 0 ]; then
        echo -e "${Green}swapfile未发现，正在为其创建swapfile${Font}"
        fallocate -l ${swapsize}M /swapfile
        if [ $? -ne 0 ]; then
            echo -e "${Red}创建swapfile失败，请检查fallocate是否支持你的文件系统或使用其他方法创建swapfile。${Font}"
            exit 1
        fi
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo "/swapfile none swap sw,pri=${swappriority} 0 0" >> /etc/fstab
        echo -e "${Green}swap创建成功，并查看信息：${Font}"
        cat /proc/swaps
        cat /proc/meminfo | grep Swap
    else
        echo -e "${Red}swapfile已存在，swap设置失败，请先运行脚本删除swap后重新设置！${Font}"
    fi
}

del_swap(){
    # 检查是否存在swapfile
    grep -q "swapfile" /etc/fstab

    # 如果存在就将其移除
    if [ $? -eq 0 ]; then
        echo -e "${Green}swapfile已发现，正在将其移除...${Font}"
        sed -i '/swapfile/d' /etc/fstab
        echo "3" > /proc/sys/vm/drop_caches
        swapoff -a
        rm -f /swapfile
        echo -e "${Green}swap已删除！${Font}"
    else
        echo -e "${Red}swapfile未发现，swap删除失败！${Font}"
    fi
}

# 开始菜单
main(){
    root_need
    ovz_no
    clear
    echo -e "———————————————————————————————————————"
    echo -e "${Green}Linux VPS一键添加/删除swap脚本${Font}"
    echo -e "${Green}1、添加swap${Font}"
    echo -e "${Green}2、删除swap${Font}"
    echo -e "———————————————————————————————————————"
    read -p "请输入数字 [1-2]:" num
    case "$num" in
        1)
            add_swap
            ;;
        2)
            del_swap
            ;;
        *)
            clear
            echo -e "${Red}请输入正确数字 [1-2]${Font}"
            sleep 2s
            main
            ;;
    esac
}

main
