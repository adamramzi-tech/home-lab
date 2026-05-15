# Hardware Build

## Objective

The goal of this project was to repurpose existing desktop hardware into a dedicated Linux-based homelab server for learning practical IT infrastructure, systems administration, networking, Docker, and remote server management.

The project began as a personal learning initiative focused on gaining hands-on experience rather than relying solely on theoretical study.

---

# Hardware Used

## Core Components

- Intel Core i5-9600KF
- MSI Z390 GAMING PRO CARBON motherboard
- PNY XLR8 16GB (2x8GB) RAM DDR3 1866MHz
- NVIDIA GTX 1060
- NZXT H500i White RGB ATX Mid Tower Case
- Western Digital Blue Desktop Hard Drive 1TB 3.5"
- Thermalright Assassin X120 Refined SE CPU Air Cooler
- Corsair CX500 500W Power Supply

---

# Physical Assembly

## Repurposing Existing Hardware

The server was built using a combination of existing desktop components and a newly purchased CPU cooler. The objective was to create a stable and efficient machine capable of running 24/7 Linux server workloads.

---

## CPU Cooler Installation

A new CPU cooler was installed before deployment to improve thermal performance and long-term stability.

Steps completed:
- Removed the previous cooler
- Cleaned old thermal paste from the CPU
- Applied fresh thermal paste
- Mounted the new CPU cooler securely
- Connected CPU fan headers
- Verified cooler clearance inside the case

This was one of the most important hardware preparation steps because the system would eventually operate continuously as a server.

---

## Internal System Preparation

Additional setup included:
- reconnecting storage drives
- reseating hardware where necessary
- verifying RAM placement
- organizing cables for airflow
- checking fan operation

The machine was prepared with long-term stability and airflow in mind rather than gaming-oriented aesthetics.

---

# Initial Boot and BIOS Verification

## POST Verification

After assembly, the system was powered on and tested to confirm:
- successful POST
- CPU detection
- memory detection
- storage detection
- fan operation

This verified that the hardware was functioning correctly before installing the operating system.

---

## BIOS Access and Configuration

The motherboard BIOS was accessed to:
- confirm hardware recognition
- verify CPU temperatures
- inspect boot devices
- review fan operation
- prepare the machine for Linux installation

---

## BIOS Update

The BIOS was updated before deploying the server operating system.

Reasons for updating:
- improve system stability
- ensure compatibility
- apply firmware improvements
- reduce potential hardware issues later

This step reinforced the importance of firmware maintenance as part of infrastructure preparation.

---

# Thermal Validation

## Temperature Checks

After installation of the new CPU cooler, temperatures were monitored to verify proper mounting and airflow.

The system maintained stable idle temperatures and operated normally after extended runtime testing.

---

# Lessons Learned

## Hardware Reliability Matters

One major takeaway from the hardware phase was that infrastructure projects begin long before software installation. Proper cooling, hardware validation, and firmware updates contribute significantly to long-term reliability.

---

## Repurposed Hardware Can Still Be Valuable

This project demonstrated that older desktop hardware can still serve effectively as a dedicated Linux server for:
- virtualization
- Docker workloads
- monitoring stacks
- networking labs
- infrastructure experimentation

---

## Incremental Troubleshooting Is Critical

The hardware build process reinforced the importance of:
- testing incrementally
- validating hardware before software deployment
- checking temperatures early
- verifying firmware and BIOS stability

These habits later became extremely valuable during Linux and Docker troubleshooting.

---

# Outcome

At the completion of the hardware phase:
- the server successfully POSTed
- temperatures were stable
- BIOS was updated
- all hardware was recognized correctly
- the machine was ready for Ubuntu Server installation

This established the foundation for the remainder of the homelab infrastructure project.
