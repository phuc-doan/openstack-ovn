# III. Chi tiết OpenStack OVN

# MỤC LỤC


# 1. Sự khác nhau giữa ML2/OVN và ML2/OVS
\- 1. Trên cùng 1 node, OVS cấu hình vlan cho các port để phân chia mạng, OVN sử dụng flow.  
\- 2. Với mạng Flat, VLAN:  
- OVS sử dụng internal VLAN, và actual VLAN, flow trong `br-provider` có nhiệm vụ swap giữa internal VLAN, và actual VLAN.
- OVN sử dụng flow tại `br-int` để gắn actual VLAN vào header của packet. Không có bất cứ flow nào trên `br-provider`.  
\- 3. Với mạng overlay:  
- OVS sử dụng `br-tun` và flow trong `br-tun` để thực hiện overlay và tráo đổi internal VLAN tag cho internal tunnel ID.
- OVN sử dụng `br-int` và flow trong `br-int` để thực hiện overlay và tráo đổi internal VLAN tag cho internal tunnel ID.
\- OVN không chỉ sử dụng 2 vswitch `br-int` và `br-provider`.  
OVS sử dụng 3 vswitch `br-int`, `br-provider` và `br-tun`.  


