# Neural Recording & Stimulation System (16-Channel)

## Overview
This project implements a **16-channel in-vitro neural recording and stimulation system** interfacing with a multielectrode array (MEA). The system enables real-time neural signal acquisition, visualization, and controlled stimulation via a host PC.

The design emphasizes **hardware/software co-design**, integrating FPGA-based control, USB communication, and a custom graphical interface.

---

## System Architecture
### 1. Neural Interface Chip
- **Chip:** Intan RHS2116  
- Provides:
  - 16-channel neural recording
  - Electrical stimulation capability
  - SPI-based digital interface

---

### 2. FPGA + USB Hardware
- FPGA module for:
  - SPI communication with neural chip
  - Data acquisition control
  - USB protocol handling  
- USB bridge module:
  - Communication between FPGA and host PC  
- Custom PCB:
  - Integrates FPGA, USB chip, and neural interface

<img width="1218" height="459" alt="image" src="https://github.com/user-attachments/assets/127f16ee-b29c-47f0-b109-98ab0e6ac077" />

---
