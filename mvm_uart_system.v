module mvm_uart_system #(
  parameter CLOCKS_PER_PULSE = 200_000_000/9600, //200_000_000/9600
            BITS_PER_WORD    = 8,
            PACKET_SIZE_TX   = BITS_PER_WORD + 5,
            W_Y_OUT          = 32,
            R=8, C=8, W_X=8, W_K=8
)(
  input  clk, rstn, rx,
  output tx
);

  localparam  W_BUS_KX = R*C*W_K + C*W_X,
              W_BUS_Y  = R*W_Y_OUT,
              W_Y      = W_X + W_K + $clog2(C);

  wire s_valid, m_valid, m_ready;
  wire [W_BUS_KX-1:0] s_data_kx;

  uart_rx #(
    .CLOCKS_PER_PULSE (CLOCKS_PER_PULSE),
    .BITS_PER_WORD (BITS_PER_WORD), 
    .W_OUT (W_BUS_KX)
  ) UART_RX (
    .clk    (clk), 
    .rstn   (rstn), 
    .rx     (rx),
    .m_valid(s_valid),
    .m_data (s_data_kx)
  );

  wire [R*W_Y  -1:0] m_data_y;
  wire s_ready;
  wire _unused = s_ready;
  axis_matvec_mul #(
    .R(R), .C(C), .W_X(W_X), .W_K(W_K)
  ) AXIS_MVM (
    .clk    (clk      ), 
    .rstn   (rstn     ),
    .s_axis_kx_tready(s_ready), // assume always valid
    .s_axis_kx_tvalid(s_valid  ), 
    .s_axis_kx_tdata (s_data_kx),
    .m_axis_y_tready (m_ready  ),
    .m_axis_y_tvalid (m_valid  ),
    .m_axis_y_tdata  (m_data_y )
  );

  // Padding to 32 bits to be read in computer
  wire [W_Y      -1:0] y_up     [R-1:0];
  wire [W_Y_OUT  -1:0] o_up   [R-1:0];
  wire [R*W_Y_OUT-1:0] o_flat;

  genvar r;
  generate
  for (r=0; r<R; r=r+1) begin
    assign y_up  [r] = m_data_y[W_Y*(r+1)-1 : W_Y*r];
    assign o_up  [r] = W_Y_OUT'($signed(y_up[r])); // sign extend to 32b
    assign o_flat[W_Y_OUT*(r+1)-1 : W_Y_OUT*r] = o_up[r];
    // assign o_flat[W_Y_OUT*(r+1)-1 : W_Y_OUT*r] = $signed(m_data_y[W_Y*(r+1)-1 : W_Y*r]);
  end
  endgenerate

  uart_tx #(
   .CLOCKS_PER_PULSE (CLOCKS_PER_PULSE),
   .BITS_PER_WORD    (BITS_PER_WORD),
   .PACKET_SIZE      (PACKET_SIZE_TX),
   .W_OUT            (W_BUS_Y)
  ) UART_TX (
   .clk     (clk      ), 
   .rstn    (rstn     ), 
   .s_ready (m_ready  ),
   .s_valid (m_valid  ), 
   .s_data_f(o_flat   ),
   .tx      (tx       )
  );  

endmodule

module axis_matvec_mul #(
    parameter R=8, C=8, W_X=8, W_K=8,
              LATENCY = $clog2(C)+1,
              W_Y = W_X + W_K + $clog2(C)
  )(
    input  clk, rstn,
    output s_axis_kx_tready, 
    input  s_axis_kx_tvalid, 
    input  [R*C*W_K + C*W_X -1:0] s_axis_kx_tdata,
    input  m_axis_y_tready,
    output m_axis_y_tvalid,
    output [R*W_Y           -1:0] m_axis_y_tdata
  );
    wire [R*C*W_K-1:0] k;
    wire [C*W_X  -1:0] x;
    assign {k, x} = s_axis_kx_tdata;

    wire [R*W_Y-1:0] i_data;
    wire i_ready;

    matvec_mul #(
      .R(R), .C(C), .W_X(W_X), .W_K(W_K)
    ) MATVEC (  
      .clk(clk    ),
      .cen(i_ready),
      .kf (k      ),
      .xf (x      ), 
      .yf (i_data )
    );

    reg [LATENCY-2:0] shift;
    reg  i_valid;

    always @(posedge clk or negedge rstn)
      if     (!rstn)   {i_valid, shift} <= 0;
      else if(i_ready) {i_valid, shift} <= {shift, s_axis_kx_tvalid};

    skid_buffer #(.WIDTH(R*W_Y)) SKID (
      .clk     (clk    ), 
      .rstn    (rstn   ), 
      .s_ready (i_ready),
      .s_valid (i_valid), 
      .s_data  (i_data ),
      .m_ready (m_axis_y_tready),
      .m_valid (m_axis_y_tvalid), 
      .m_data  (m_axis_y_tdata )
    );

    assign s_axis_kx_tready = i_ready;

endmodule