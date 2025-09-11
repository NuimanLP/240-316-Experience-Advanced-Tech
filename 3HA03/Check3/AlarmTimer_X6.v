// ========================= AlarmTimer_X6_verilog.v =========================
// FPGA 50 MHz | ID: 066 → X = 6 วินาที
// S5_n: เริ่มนับถอยหลัง | S6_n: หยุดเสียง | ถึง 0 → เล่นสองโทนสลับ 4 Hz (ทดลองที่ 2)
// ใช้กับ Active buzzer (ผ่าน R ~200Ω)

`timescale 1ns/1ps

// ------------------ ตัวสร้างเสียงสองโทน สลับทุก 0.25s (4 Hz) ------------------
module AlarmTimer_X6 #(
    parameter integer IN_CLK    = 50_000_000,
    parameter integer FREQ1_HZ  = 1000,
    parameter integer FREQ2_HZ  = 8000,
    parameter integer TEMPO_HZ  = 4
)(
    input  wire clk,
    input  wire enable,   // 1=เปิดเสียง, 0=ปิด (เอาต์พุต 0)
    output reg  BZ1
);
    localparam integer DIV1   = IN_CLK / (2*FREQ1_HZ);
    localparam integer DIV2   = IN_CLK / (2*FREQ2_HZ);
    localparam integer DIVTMP = IN_CLK / (TEMPO_HZ);

    reg [31:0] c1=0, c2=0, ctmp=0;
    reg s1=1'b0, s2=1'b0;
    reg sel_tone=1'b0;

    // จังหวะสลับโทน (4 Hz ⇒ 0.25 s)
    always @(posedge clk) begin
        if (ctmp == DIVTMP-1) begin ctmp<=0; sel_tone<=~sel_tone; end
        else ctmp <= ctmp + 1'b1;
    end

    // โทน 1
    always @(posedge clk) begin
        if (c1 == DIV1-1) begin c1<=0; s1<=~s1; end
        else c1 <= c1 + 1'b1;
    end

    // โทน 2
    always @(posedge clk) begin
        if (c2 == DIV2-1) begin c2<=0; s2<=~s2; end
        else c2 <= c2 + 1'b1;
    end

    // ส่งออก (ปิดเสียงเมื่อ enable=0)
    always @(posedge clk) begin
        if (enable) BZ1 <= (sel_tone ? s2 : s1);
        else        BZ1 <= 1'b0;
    end
endmodule


// ------------------ Debounce + rising-edge (one-shot) ------------------
module DebounceEdge #(
    parameter integer IN_CLK = 50_000_000,
    parameter integer MS     = 5 // หน่วง 5 ms
)(
    input  wire clk,
    input  wire btn_n,     // ปุ่มภายนอก active-low (กด=0)
    output reg  rise       // พัลส์ 1 คลอก ตอน "กด"
);
    localparam integer LIM = (IN_CLK/1000)*MS;

    reg sync0=1'b1, sync1=1'b1;
    reg [31:0] dc=0;
    reg stable=1'b0, stable_d=1'b0;

    // ซิงค์เข้าคลอก
    always @(posedge clk) begin
        sync0 <= btn_n;
        sync1 <= sync0;
    end

    // ภายในใช้ active-high: กด=1
    wire btn = ~sync1;

    // debounce
    always @(posedge clk) begin
        if (btn != stable) begin
            if (dc == LIM-1) begin
                stable <= btn;
                dc     <= 0;
            end else dc <= dc + 1'b1;
        end else begin
            dc <= 0;
        end
    end

    // rising-edge (0→1)
    always @(posedge clk) begin
        stable_d <= stable;
        rise     <= (stable & ~stable_d);
    end
endmodule


// ------------------ Tick 1 Hz สำหรับนับวินาที ------------------
module Tick1Hz #(
    parameter integer IN_CLK = 50_000_000
)(
    input  wire clk,
    output reg  tick
);
    localparam integer DIV = IN_CLK; // นับ 0..DIV-1
    reg [31:0] c=0;

    always @(posedge clk) begin
        if (c == DIV-1) begin
            c    <= 0;
            tick <= 1'b1;
        end else begin
            c    <= c + 1'b1;
            tick <= 1'b0;
        end
    end
endmodule


// ------------------ Top: นาฬิกาปลุก X วินาที ------------------
module AlarmTimer_X #(
    parameter integer IN_CLK = 50_000_000,
    parameter integer X_SEC  = 6      // 066 → X=6 (ถ้าเลขท้ายเป็น 0 ให้ใช้ 9)
)(
    input  wire clk,     // 50 MHz
    input  wire S5_n,    // เริ่ม (active-low)
    input  wire S6_n,    // หยุดเสียง (active-low)
    output wire BZ1,     // ไป Active buzzer ผ่าน R ~200Ω
    output reg  [7:0] sec_left, // optional แสดงผล
    output reg  alarm_on
);
    // ค่าเริ่มต้น
    initial begin
        sec_left = 0;
        alarm_on = 0;
    end

    // ปุ่มหลัง debounce → พัลส์เดียว
    wire start_pulse, stop_pulse;
    DebounceEdge #(IN_CLK, 5) db_start(.clk(clk), .btn_n(S5_n), .rise(start_pulse));
    DebounceEdge #(IN_CLK, 5) db_stop (.clk(clk), .btn_n(S6_n), .rise(stop_pulse));

    // 1 Hz tick
    wire tick1s;
    Tick1Hz #(IN_CLK) t1(.clk(clk), .tick(tick1s));

    // FSM (Verilog-2001)
    localparam [1:0] IDLE  = 2'd0,
                     COUNT = 2'd1,
                     ALARM = 2'd2;
    reg [1:0] st = IDLE;

    // นับถอยหลัง + สภาวะ
    always @(posedge clk) begin
        case (st)
            IDLE: begin
                alarm_on <= 1'b0;
                sec_left <= X_SEC[7:0];
                if (start_pulse) st <= COUNT;
            end

            COUNT: begin
                if (tick1s) begin
                    if (sec_left > 0) sec_left <= sec_left - 1'b1;
                    if (sec_left == 1) st <= ALARM; // วินาทีถัดไปจะเป็น 0
                end
            end

            ALARM: begin
                alarm_on <= 1'b1;          // เปิดเสียงสองโทนสลับ
                if (stop_pulse) begin      // กด S6 เพื่อล้างและพร้อมเริ่มใหม่
                    alarm_on <= 1'b0;
                    st       <= IDLE;
                end
            end

            default: st <= IDLE;
        endcase
    end

    // ตัวสร้างเสียงสองโทน (ทดลองที่ 2)
    TwoToneSwitcher #(
        .IN_CLK(IN_CLK),
        .FREQ1_HZ(1000),
        .FREQ2_HZ(8000),
        .TEMPO_HZ(4)
    ) tone (
        .clk(clk),
        .enable(alarm_on),
        .BZ1(BZ1)
    );
endmodule

// ------------------ Top-level ที่ใช้จริงในโปรเจกต์ ------------------
// แก้ชื่อโมดูลนี้ใน Assignments → Top-Level Entity เป็น "top"
module top (
    input  wire clk,     // 50 MHz oscillator
    input  wire S5_n,    // ปุ่มเริ่ม (active-low)
    input  wire S6_n,    // ปุ่มหยุด (active-low)
    output wire BZ1
);
    // เลขท้ายรหัส 066 → X = 6 (ถ้าเป็น 0 ให้ใช้ 9)
    AlarmTimer_X #(
        .IN_CLK(50_000_000),
        .X_SEC(6)
    ) u_alarm (
        .clk(clk),
        .S5_n(S5_n),
        .S6_n(S6_n),
        .BZ1(BZ1),
        .sec_left(),     // ไม่ใช้ก็ปล่อยไว้
        .alarm_on()
    );
endmodule
