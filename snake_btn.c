/* snake_btn.c -- Snake di OLED SSD1306 128x64 via I2C bit-bang.
 *   Input : btnU/D/L/R onboard Basys3 -> pindata[0..3].
 *   Output: OLED SSD1306 (datanw[0]=SCL, datanw[1]=SDA, open-drain).
 *   Grid  : 32x16 sel, tiap sel 4x4 piksel.
 *   Aturan: tidak bisa balik 180°. Makan -> memanjang. Tabrak -> Game Over.
 */
#include "mriscv.h"

/* ===================== I2C ===================== */
#define SCL_PIN  0
#define SDA_PIN  1
#define I2C_ADDR 0x78
#define CTL_CMD  0x00
#define CTL_DATA 0x40

static void ihold(void){ volatile int i; for(i=0;i<4;i++); }
static void scl(unsigned v){ gpio_pin(SCL_PIN,v); }
static void sda(unsigned v){ gpio_pin(SDA_PIN,v); }
static void i2c_start(void){ sda(1);scl(1);ihold();sda(0);ihold();scl(0);ihold(); }
static void i2c_stop (void){ sda(0);scl(1);ihold();sda(1);ihold(); }
static void i2c_tx(unsigned b){
    for(int i=0;i<8;i++){sda((b>>7)&1);b<<=1;scl(1);ihold();scl(0);ihold();}
    sda(1);scl(1);ihold();scl(0);ihold();
}
static void cmd(unsigned c){
    i2c_start();i2c_tx(I2C_ADDR);i2c_tx(CTL_CMD);i2c_tx(c);i2c_stop();
}

/* ===================== SSD1306 ===================== */
static void ssd1306_init(void){
    cmd(0xAE);cmd(0xD5);cmd(0x80);cmd(0xA8);cmd(0x3F);cmd(0xD3);cmd(0x00);
    cmd(0x40);cmd(0x8D);cmd(0x14);cmd(0x20);cmd(0x00);cmd(0xA1);cmd(0xC8);
    cmd(0xDA);cmd(0x12);cmd(0x81);cmd(0xCF);cmd(0xD9);cmd(0xF1);cmd(0xDB);
    cmd(0x40);cmd(0xA4);cmd(0xA6);cmd(0xAF);
}
static void clear(void){
    cmd(0x21);cmd(0);cmd(127);cmd(0x22);cmd(0);cmd(7);
    i2c_start();i2c_tx(I2C_ADDR);i2c_tx(CTL_DATA);
    for(int i=0;i<1024;i++) i2c_tx(0x00);
    i2c_stop();
}

/* gambar/hapus sel grid 4x4 piksel */
static void draw_cell(int gx, int gy, int on){
    int px = gx * 4;
    int py = gy * 4;
    int page = py / 8;
    int bit_off = py % 8;
    unsigned mask = (unsigned)(0x0F << bit_off) & 0xFF;
    cmd(0x21);cmd((unsigned)px);cmd((unsigned)(px+3));
    cmd(0x22);cmd((unsigned)page);cmd((unsigned)page);
    i2c_start();i2c_tx(I2C_ADDR);i2c_tx(CTL_DATA);
    for(int i=0;i<4;i++) i2c_tx(on ? mask : 0x00);
    i2c_stop();
    if(bit_off > 4) {
        unsigned mask2 = (unsigned)(0x0F >> (8 - bit_off)) & 0xFF;
        cmd(0x21);cmd((unsigned)px);cmd((unsigned)(px+3));
        cmd(0x22);cmd((unsigned)(page+1));cmd((unsigned)(page+1));
        i2c_start();i2c_tx(I2C_ADDR);i2c_tx(CTL_DATA);
        for(int i=0;i<4;i++) i2c_tx(on ? mask2 : 0x00);
        i2c_stop();
    }
}

/* ===================== font & skor ===================== */
static const unsigned char font8x8[10][8]={
  {0x3E,0x51,0x49,0x45,0x3E,0,0,0},{0x00,0x42,0x7F,0x40,0x00,0,0,0},
  {0x42,0x61,0x51,0x49,0x46,0,0,0},{0x21,0x41,0x45,0x4B,0x31,0,0,0},
  {0x18,0x14,0x12,0x7F,0x10,0,0,0},{0x27,0x45,0x45,0x45,0x39,0,0,0},
  {0x3C,0x4A,0x49,0x49,0x30,0,0,0},{0x01,0x71,0x09,0x05,0x03,0,0,0},
  {0x36,0x49,0x49,0x49,0x36,0,0,0},{0x06,0x49,0x49,0x29,0x1E,0,0,0},
};
static void draw_digit(int page, int col, int d, int on){
    if(d<0) d=0;
    if(d>9) d=9;
    cmd(0x21);cmd((unsigned)col);cmd((unsigned)(col+7));
    cmd(0x22);cmd((unsigned)page);cmd((unsigned)page);
    i2c_start();i2c_tx(I2C_ADDR);i2c_tx(CTL_DATA);
    for(int i=0;i<8;i++) i2c_tx(on ? font8x8[d][i] : 0x00);
    i2c_stop();
}
static void draw_score(int sc, int on){
    int t=0, o=sc;
    while(o>=10){o-=10;t++;} if(t>9)t=9;
    draw_digit(7, 56, t, on);
    draw_digit(7, 65, o, on);
}

/* ===================== game ===================== */
#define GW       32
#define GH       16
#define MAX_LEN  128

/* arah: 0=U 1=D 2=L 3=R -- sama dengan bit pindata */
static const signed char DX[]={ 0, 0,-1, 1};
static const signed char DY[]={-1, 1, 0, 0};
static const int OPP[]={1,0,3,2};   /* kebalikan tiap arah */

#define BTN_U 0
#define BTN_D 1
#define BTN_L 2
#define BTN_R 3
#define NO_BTN -1

static unsigned char bx[MAX_LEN], by[MAX_LEN];
static unsigned char grid[GH][GW];
static int  head_i, tail_i, dir_i, score_i;
static unsigned char food_x, food_y;

static void place_food(void){
    unsigned char x=food_x, y=food_y;
    for(int i=0;i<GW*GH;i++){
        x++; if(x>=GW){x=0;y++;if(y>=GH)y=0;}
        if(!grid[y][x]){ food_x=x; food_y=y; grid[y][x]=2; draw_cell(x,y,1); return; }
    }
}
static void game_init(void){
    for(int r=0;r<GH;r++) for(int c=0;c<GW;c++) grid[r][c]=0;
    for(int i=0;i<3;i++){
        bx[i]=(unsigned char)(GW/2-1+i);
        by[i]=(unsigned char)(GH/2);
        grid[GH/2][GW/2-1+i]=1;
    }
    head_i=2; tail_i=0; dir_i=BTN_R; score_i=0;
    food_x=0; food_y=0;
}

/* baca tombol: kembalikan arah (0-3) atau NO_BTN.
   Prioritas: U > D > L > R (hanya ambil 1 tombol per langkah). */
static int read_btn(void){
    if(gpio_rd(BTN_U)) return BTN_U;
    if(gpio_rd(BTN_D)) return BTN_D;
    if(gpio_rd(BTN_L)) return BTN_L;
    if(gpio_rd(BTN_R)) return BTN_R;
    return NO_BTN;
}

/* ===================== MAIN ===================== */
int main(void){
    sda(1); scl(1);
    ssd1306_init();
    clear();

restart:
    clear();
    game_init();
    for(int i=0;i<3;i++) draw_cell(bx[i],by[i],1);
    place_food();
    draw_score(0,1);

    /* TICK_MAX: jumlah iterasi pembacaan tombol per langkah ular.
       Lebih besar = lebih lambat. Sesuaikan dengan kecepatan yang nyaman. */
#define TICK_MAX 1200
    int tick=0;
    int queued_dir=dir_i;   /* arah yang diantri saat tombol ditekan */
    int prev_btn=NO_BTN;    /* untuk deteksi tepi (edge-triggered) */

    for(;;){
        /* --- baca tombol (edge-triggered: hanya saat baru ditekan) --- */
        int btn=read_btn();
        if(btn != prev_btn && btn != NO_BTN){
            /* abaikan jika berlawanan 180° */
            if(btn != OPP[dir_i]) queued_dir=btn;
        }
        prev_btn=btn;

        /* --- gerak ular setiap TICK_MAX iterasi --- */
        tick++;
        if(tick < TICK_MAX) continue;
        tick=0;

        dir_i=queued_dir;
        int nx=(int)bx[head_i]+DX[dir_i];
        int ny=(int)by[head_i]+DY[dir_i];

        /* tabrakan dinding atau diri */
        if(nx<0||nx>=GW||ny<0||ny>=GH) goto game_over;
        if(grid[ny][nx]==1)             goto game_over;

        int ate=(grid[ny][nx]==2);
        grid[ny][nx]=1;
        head_i=(head_i+1)%MAX_LEN;
        bx[head_i]=(unsigned char)nx;
        by[head_i]=(unsigned char)ny;
        draw_cell(nx,ny,1);

        if(!ate){
            draw_cell(bx[tail_i],by[tail_i],0);
            grid[by[tail_i]][bx[tail_i]]=0;
            tail_i=(tail_i+1)%MAX_LEN;
        } else {
            draw_score(score_i,0);
            score_i++;
            draw_score(score_i,1);
            place_food();
        }
        continue;

game_over:
        clear();
        draw_score(score_i,1);
        /* tunggu semua tombol dilepas lalu tekan salah satu untuk restart */
        while(read_btn()!=NO_BTN){}
        while(read_btn()==NO_BTN){}
        goto restart;
    }
}