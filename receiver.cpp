#include <iostream>
#include <cstring>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <unistd.h>

using namespace std;

int main() {
    struct sockaddr_can addr; // CAN interface address
    struct ifreq ifr; // network interface name
    struct can_frame frame; // CAN message storage

    int s = socket(PF_CAN, SOCK_RAW, CAN_RAW);

    if (s < 0) {
        perror("Socket");
        return 1;
    }

    strcpy(ifr.ifr_name, "can10");
    if (ioctl(s, SIOCGIFINDEX, &ifr) < 0) {
        perror("ioctl");
        return 1;
    };

    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;

    if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("Bind");
        return 1;
    }

    cout << "Listening on can10..." << endl;

    while (true) {
        int nbytes = read(s, &frame, sizeof(struct can_frame));
        if (nbytes > 0 && frame.can_id == 0x123 && frame.can_dlc >= 3) {
            // Speed
            int speed_int = (frame.data[0] << 8) | frame.data[1];
            int speed_frac = frame.data[2];
            float speed = speed_int + (speed_frac / 100.0f);

            // RPM
            int rpm_int = (frame.data[3] << 8) | frame.data[4];
            int rpm_frac = frame.data[5];
            float rpm = rpm_int + (rpm_frac / 100.0f);

            cout << "Speed: " << speed << " cm/s | RPM: " << rpm << endl;
        }
    }

    close(s);
    return 0;
}
