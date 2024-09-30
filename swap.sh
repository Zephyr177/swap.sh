#!/usr/bin/env bash
#Blog:https://www.moerats.com/

Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

# root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}Error: This script must be run as root!${Font}"
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

add_swap(){
    echo -e "${Green}请输入需要添加的swap，建议为内存的2倍！${Font}"
    read -p "请输入swap数值 (MB): " swapsize

    # 检查是否存在swapfile
    grep -q "swapfile" /etc/fstab

    # 如果不存在将为其创建swap
    if [ $? -ne 0 ]; then
        echo -e "${Green}swapfile未发现，正在为其创建swapfile${Font}"
        fallocate -l ${swapsize}M /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
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

set_swappiness(){
    echo -e "${Green}当前的swappiness值为：$(cat /proc/sys/vm/swappiness)${Font}"
    echo -e "${Green}建议设置为10-60之间的值。${Font}"
    read -p "请输入新的swappiness值 (0-100): " swvalue

    # 验证输入是否为数字且在0-100之间
    if ! [[ "$swvalue" =~ ^[0-9]+$ ]] || [ "$swvalue" -lt 0 ] || [ "$swvalue" -gt 100 ]; then
        echo -e "${Red}无效的输入，请输入0到100之间的数字！${Font}"
        return
    fi

    # 设置当前swappiness值
    sysctl vm.swappiness=${swvalue}

    # 持久化设置到 /etc/sysctl.conf
    if grep -q "^vm.swappiness" /etc/sysctl.conf; then
        sed -i "s/^vm.swappiness.*/vm.swappiness = ${swvalue}/" /etc/sysctl.conf
    else
        echo "vm.swappiness = ${swvalue}" >> /etc/sysctl.conf
    fi

    echo -e "${Green}swappiness已设置为${swvalue}。${Font}"
}

# 开始菜单
main(){
    root_need
    ovz_no
    clear
    echo -e "———————————————————————————————————————"
    echo -e "${Green}Linux VPS一键管理swap脚本${Font}"
    echo -e "${Green}1、添加swap${Font}"
    echo -e "${Green}2、删除swap${Font}"
    echo -e "${Green}3、调整swap使用优先级（swappiness）${Font}"
    echo -e "———————————————————————————————————————"
    read -p "请输入数字 [1-3]:" num
    case "$num" in
        1)
            add_swap
            ;;
        2)
            del_swap
            ;;
        3)
            set_swappiness
            ;;
        *)
            clear
            echo -e "${Red}请输入正确的数字 [1-3]${Font}"
            sleep 2s
            main
            ;;
    esac
}

main
