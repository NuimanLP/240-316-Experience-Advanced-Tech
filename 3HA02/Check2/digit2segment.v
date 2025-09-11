module digit2segment(
    input  wire        clk,                 // 50 MHz
    output wire [6:0]  segmentShow,         // a..g (shared)
    output wire        dp,                  // decimal point
    output wire        segment1,            // digit enable: rightmost (d1)
    output wire        segment2,            // next (d10)
    output wire        segment3,            // next (d100)
    output wire        segment4             // leftmost (d1000)
);
    //==================== Config ====================
    parameter integer inClk    = 50_000_000;   // reference clock
    parameter integer perDigit = 60;           // ≥60 Hz per digit
    localparam integer refreshT = inClk / (perDigit * 4); // tick per multiplex step

    // <<< เปลี่ยนค่านี้ให้เป็น "เลขตัวสุดท้ายของรหัส นศ." ของคุณ >>>
    parameter [3:0] LAST_DIGIT = 4'd0;

    //==================== Clock divider =============
    reg [26:0] clkRefresh = 27'd0;
    wire tick = (clkRefresh == refreshT-1);

    always @(posedge clk) begin
        clkRefresh <= tick ? 27'd0 : clkRefresh + 27'd1;
    end

    //==================== Scanner (0..3) ============
    reg [1:0] segmentID = 2'd0;  // 00..11 -> d1,d10,d100,d1000
    always @(posedge clk) begin
        if (tick) segmentID <= segmentID + 2'd1;
    end

    //==================== Digits to show ============
    // โจทย์ให้ทั้ง 4 หลักเป็นเลขเดียวกัน (เลขท้ายรหัส นศ.)
    wire [3:0] digit    = LAST_DIGIT;  // d1   (ขวาสุด)
    wire [3:0] ten      = LAST_DIGIT;  // d10
    wire [3:0] hundred  = LAST_DIGIT;  // d100
    wire [3:0] thousand = LAST_DIGIT;  // d1000 (ซ้ายสุด)

    //==================== Mux: choose active digit ==
    // active-high (ตามทรานซิสเตอร์ NPN ในสเกเมติก)
    reg s1, s2, s3, s4;
    reg [3:0] num;                     // current BCD

    always @(*) begin
        // default off
        s1 = 1'b0; s2 = 1'b0; s3 = 1'b0; s4 = 1'b0;
        case (segmentID)
            2'b00: begin s1 = 1'b1; num = digit;    end   // ขวาสุด d1
            2'b01: begin s2 = 1'b1; num = ten;      end   // d10
            2'b10: begin s3 = 1'b1; num = hundred;  end   // d100
            2'b11: begin s4 = 1'b1; num = thousand; end   // ซ้ายสุด d1000
        endcase
    end

    //==================== 7-seg encoder (CC) ========
    // บิตเรียง a b c d e f g, 1 = ติด (common-cathode)
    reg [6:0] abcdefg;
    always @(*) begin
        case (num)
            4'd0: abcdefg = 7'b1111110;
            4'd1: abcdefg = 7'b0110000;
            4'd2: abcdefg = 7'b1101101;
            4'd3: abcdefg = 7'b1111001;
            4'd4: abcdefg = 7'b0110011;
            4'd5: abcdefg = 7'b1011011;
            4'd6: abcdefg = 7'b1011111;
            4'd7: abcdefg = 7'b1110000;
            4'd8: abcdefg = 7'b1111111;
            4'd9: abcdefg = 7'b1111011;
            default: abcdefg = 7'b0000000; // นอกช่วง -> ดับทั้งหมด
        endcase
    end

    //==================== Outputs ====================
    assign segmentShow = abcdefg; // CC: 1=on
    assign dp          = 1'b0;    // ปิดจุดทศนิยม
    assign segment1    = s1;
    assign segment2    = s2;
    assign segment3    = s3;
    assign segment4    = s4;

endmodule
