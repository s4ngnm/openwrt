#!/bin/sh

# --- CẤU HÌNH ---
WAN_IF="wan"
LAN_IF="lan"
PPPOE_USER="Bdfdl-171217-657"
PPPOE_PASS="fd59657"

# MAC Address (Dạng XX:XX:XX:XX:XX:XX)
NEW_MAC_WAN="A0:21:AA:BE:62:1C"
NEW_MAC_LAN="A0:21:AA:BE:62:1B"

# Wireless
SSID="Sang"
WIFI_KEY="88888888"

# DNS (Cloudflare & Google)
DNS_SERVERS="1.1.1.1 1.0.0.1 8.8.8.8"

echo "--- BẮT ĐẦU TỐI ƯU HÓA HỆ THỐNG ---"

# 1. TỐI ƯU MAC ADDRESS (CẤU TRÚC DEVICE DSA)
# OpenWrt 24.10 ưu tiên định nghĩa macaddr trong mục 'device'
echo "[1/4] Đang đổi MAC Address..."
WAN_DEV=$(uci get network.$WAN_IF.device 2>/dev/null || echo "eth1")
LAN_DEV=$(uci get network.$LAN_IF.device 2>/dev/null || echo "br-lan")

uci set network.$WAN_DEV=device
uci set network.$WAN_DEV.name="$WAN_DEV"
uci set network.$WAN_DEV.macaddr="$NEW_MAC_WAN"

uci set network.$LAN_DEV=device
uci set network.$LAN_DEV.name="$LAN_DEV"
uci set network.$LAN_DEV.macaddr="$NEW_MAC_LAN"

# 2. CẤU HÌNH PPPOE & TỐI ƯU MTU
# Tự động set MTU 1492 (chuẩn PPPoE) để tránh phân mảnh gói tin
echo "[2/4] Cấu hình PPPoE..."
uci set network.$WAN_IF.proto='pppoe'
uci set network.$WAN_IF.username="$PPPOE_USER"
uci set network.$WAN_IF.password="$PPPOE_PASS"
uci set network.$WAN_IF.mtu='1492'
# Tắt nhận DNS từ ISP
uci set network.$WAN_IF.peerdns='0'

# Xóa DNS cũ và thêm DNS mới sạch sẽ
uci del network.$WAN_IF.dns
for dns in $DNS_SERVERS; do
    uci add_list network.$WAN_IF.dns="$dns"
done

# 3. TỐI ƯU WIRELESS (WPA3 & BĂNG THÔNG)
echo "[3/4] Tối ưu hóa sóng Wifi..."
wifi_idx=0
while uci get wireless.@wifi-iface[$wifi_idx] >/dev/null 2>&1; do
    uci set wireless.@wifi-iface[$wifi_idx].ssid="$SSID"
    uci set wireless.@wifi-iface[$wifi_idx].key="$WIFI_KEY"
    # Ưu tiên WPA2/WPA3 hỗn hợp để bảo mật hơn
    uci set wireless.@wifi-iface[$wifi_idx].encryption='sae-mixed'
    # Tắt tính năng ngắt kết nối yếu để ổn định hơn
    uci set wireless.@wifi-iface[$wifi_idx].disassoc_low_ack='0'
    wifi_idx=$((wifi_idx + 1))
done

# Tối ưu radio (độ rộng kênh)
for radio in $(uci show wireless | grep "=wifi-device" | cut -d'.' -f2 | cut -d'=' -f1); do
    uci set wireless.$radio.disabled='0'
    uci set wireless.$radio.country='US' # Mở rộng công suất phát (tùy khu vực)
    # Tự động chọn kênh nhưng ép độ rộng 40Mhz cho 2.4G và 80Mhz cho 5G
    [ "$(uci get wireless.$radio.band)" = "5g" ] && uci set wireless.$radio.htmode='VHT80'
    [ "$(uci get wireless.$radio.band)" = "2g" ] && uci set wireless.$radio.htmode='HT40'
done

# 4. TỐI ƯU HỆ THỐNG (OFFLOADING)
echo "[4/4] Bật tăng tốc phần cứng (Hardware Flow Offloading)..."
uci set firewall.@defaults[0].flow_offloading='1'
uci set firewall.@defaults[0].flow_offloading_hw='1' # Nếu phần cứng hỗ trợ

# ÁP DỤNG CẤU HÌNH
echo "--- ĐANG LƯU VÀ KHỞI ĐỘNG LẠI DỊCH VỤ ---"
uci commit
/etc/init.d/network restart
/etc/init.d/firewall restart
wifi up

echo "HOÀN TẤT! Router sẽ ổn định và nhanh hơn."
