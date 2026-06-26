// basys3_top -- snake-btn project
// btnU/D/L/R -> pindata[0..3] (input arah ular)
// GPIO datanw[0]=SCL, datanw[1]=SDA (OLED I2C open-drain)
// SPI loader tetap di JA, POR otomatis.
module basys3_top (
    input  clk100,
    input  btnC,                            // reset manual
    input  btnU, btnD, btnL, btnR,          // kontrol snake
    output [7:0] led,                       // debug
    output oled_scl, oled_sda,              // OLED I2C (open-drain)
    input  spi_sclk, spi_ceb, spi_mosi,
    output spi_miso
);
    // Power-On Reset (~0.65 ms @ 100 MHz)
    reg [15:0] por_cnt = 16'd0;
    reg        por_n   = 1'b0;
    always @(posedge clk100) begin
        if (por_cnt != 16'hFFFF) begin por_cnt <= por_cnt + 1'b1; por_n <= 1'b0; end
        else                          por_n <= 1'b1;
    end
    wire rst_n = por_n & ~btnC;

    // Clock /64: 100 MHz -> ~1.5625 MHz
    reg [5:0] divcnt = 6'd0;
    always @(posedge clk100) divcnt <= divcnt + 1'b1;
    wire clk = divcnt[5];

    // Sinkronisasi tombol (2 FF, active-high)
    reg [1:0] sU=0, sD=0, sL=0, sR=0;
    always @(posedge clk) begin
        sU <= {sU[0], btnU};
        sD <= {sD[0], btnD};
        sL <= {sL[0], btnL};
        sR <= {sR[0], btnR};
    end
    // pindata: [0]=U [1]=D [2]=L [3]=R
    wire [7:0] pindata = {4'b0, sR[1], sL[1], sD[1], sU[1]};

    wire trap;
    wire [11:0] dac_data;
    wire [7:0]  gpio_Tx, gpio_Rx, gpio_datanw, gpio_DSE;
    wire        sc, ss, sd;

    impl_axi u_impl (
        .CLK                    (clk),
        .RST                    (rst_n),
        .trap                   (trap),
        .spi_axi_master_CEB     (spi_ceb),
        .spi_axi_master_SCLK    (spi_sclk),
        .spi_axi_master_DATA    (spi_mosi),
        .spi_axi_master_DOUT    (spi_miso),
        .DAC_interface_AXI_DATA (dac_data),
        .ADC_interface_AXI_BUSY (1'b0),
        .ADC_interface_AXI_DATA (10'd0),
        .completogpio_pindata   (pindata),
        .completogpio_Rx        (gpio_Rx),
        .completogpio_Tx        (gpio_Tx),
        .completogpio_datanw    (gpio_datanw),
        .completogpio_DSE       (gpio_DSE),
        .spi_axi_slave_CEB      (sc),
        .spi_axi_slave_SCLK     (ss),
        .spi_axi_slave_DATA     (sd)
    );

    assign led = gpio_datanw;

    // OLED I2C open-drain: datanw=1 -> lepas (high via pull-up), =0 -> tarik low
    assign oled_scl = gpio_datanw[0] ? 1'bz : 1'b0;
    assign oled_sda = gpio_datanw[1] ? 1'bz : 1'b0;
endmodule