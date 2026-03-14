# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 0x1
    dut.ui_in.value = 0x0
    dut.uio_in.value = 0x0
    dut.rst_n.value = 0x0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 0x1
    dut._log.info("Test project behavior")

    # Test the behavior of the project here
    for i in range(0xFF):
        dut._log.info(f"Testing input value: 0x{i:02X}")
        dut.ui_in.value = i
        await ClockCycles(dut.clk, 5)
        dut._log.info(f"Output value: 0x{dut.uo_out.value:02X}")
        assert dut.uo_out.value == is_prime(i), f"Expected output 0x{i:02X}, got 0x{dut.uo_out.value:02X}"
        
def is_prime(n):
    if n <= 1:
        return 0
    for j in range(2, int(n**0.5) + 1):
        if n % j == 0:
            return 0
    return 1


# run the test
if __name__ == "__main__":
    import cocotb
    cocotb.start