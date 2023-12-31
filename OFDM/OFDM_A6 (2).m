

clc
close all
clear all
bpsk_ber_pr=[];
bpsk_ber_thry=[];
qpsk_ber_pr=[];
qpsk_ber_thry=[];

B=100; %bandwidth in kHz
f=5;   %subcarrier bandwidth in kHz
scb=B/f;% no of sub carriers
N=1000; % no of bits
% generating N random bits
bbitg=randi([0 1],1,N);
% bpsk and qpsk modulation (bits to symbols mapping)
bx=dig_mod_bpsk(bbitg);
qx=dig_mod_qpsk(bbitg); 

subplot(2,2,1);
stem(bx);
xlabel('time');
ylabel('bpsk symbols amp')
title('frequency plot before ofdm with bpsk mod');

subplot(2,2,2);
stem((abs(qx)));
xlabel('time');
ylabel('qpsk symbols amp');
title('frequency plot before ofdm with qpsk mod');
figure;
%in the frequency plot, each subcarrier must transmit N/(total no of subcarries) i.e N/(B/f) symbols 
%since the no of bits generated is high(N=1000),each subcarrier must transmit 50 symbols in bpsk and 25 symbols in qpsk
% serial to parallel
bsp1=reshape(bx,[scb,N/scb]);
a=N/(2*scb);
qsp1=reshape(qx,[scb,a]);  
% ifft application on bpsk and qpsk modulated symbols 
bifft=ifft(bsp1);
qifft=ifft(qsp1);
%parallel to serial 
bps1=reshape(bifft,[1,N]);
qps1=reshape(qifft,[1,N/2]);

subplot(2,2,1);
plot(abs(bps1));
xlabel('time');
ylabel('ofdm symbols amp')
title('ofdm Time axis plot with bpsk mod');

subplot(2,2,2);
plot(abs(qps1));
xlabel('time');
ylabel('ofdm symbols amp')
title('ofdm Time axis plot with qpsk mod');
figure;
for EbNo_dB=0:1:10
EbNo_L=10^(EbNo_dB/10); %converting Eb/N dB toEb/No linear
bpsk_snr_L=EbNo_L;     %defining bpsk snr linear
qpsk_snr_L=(2*EbNo_L);  %defining qpsk snr linear

bpsk_ser_count=0; %initialising error count to zero
qpsk_ber_count=0; %initialising error count to zero

% calucating avg symbol energy for ofdm symbols generated by bpsk and qpsk modulation
Ebpsk_ofdm=energybpsk(bps1);
Eqpsk_ofdm=energyqpsk(qps1); 
 % bpsk standard deviation
sd_b=sqrt(Ebpsk_ofdm/(2*bpsk_snr_L));
sd_qpsk=sqrt(Eqpsk_ofdm/(2*qpsk_snr_L));
for iter=1:1000
% generating AWGN noise
bn=sd_b*(randn(1,N)+1i*randn(1,N));
qn=sd_qpsk*(randn(1,N/2)+1i*randn(1,N/2)); 
% addition of AWGN noise
by=bps1+bn; %for bpsk symbols
qy=qps1+qn; %for qpsk symbols
% serial to parallel
bsp2=reshape(by,[scb,N/scb]);
qsp2=reshape(qy,[scb,N/(2*scb)]);
% fft on received data
bfft=fft(bsp2);
qfft=fft(qsp2); 
%parallel to serial
bps2=reshape(bfft,[1,N]);
qps2=reshape(qfft,[1,N/2]);
% ML detection
bx_cp=MLdetcbpsk(bps2);
qx_cp=MLdetcqpsk(qps2);
% bpsk and qpsk demodulation 
bpskbx_cp=dig_demod_bpsk(bx_cp);
qpskqx_cp=dig_demod_qpsk(qx_cp); 
% calculating no of bits in error
bpsk_ber_count=bpsk_ser_count+sum(bbitg~=bpskbx_cp);
qpsk_ber_count=qpsk_ber_count+sum(bbitg~=qpskqx_cp); 
end

bpsk_ber=bpsk_ber_count/(N);
bpsk_ber_pr=[bpsk_ber_pr bpsk_ber];% ber of bpsk simulated

bpsk_ber_try1=qfunc(sqrt(bpsk_snr_L*2));
bpsk_ber_thry=[bpsk_ber_thry bpsk_ber_try1]; % ber of bpsk theoritical

qpsk_ber=qpsk_ber_count/(N);
qpsk_ber_pr=[qpsk_ber_pr qpsk_ber]; % ber of qpsk simulated
qpsk_ber_try1=qfunc(sqrt(EbNo_L*2));
qpsk_ber_thry=[qpsk_ber_thry qpsk_ber_try1];  % ber of qpsk theoritical

end
%BER vs snr plot
EbNo_dB=0:1:10;
semilogy(EbNo_dB,qpsk_ber_pr,'-k',EbNo_dB,qpsk_ber_thry,'-v',EbNo_dB,bpsk_ber_pr,'-o',EbNo_dB,bpsk_ber_thry,'-x');
xlabel('EbNodB');
ylabel('BER/SER');
title('BER vs SNR');
legend('qpskber prac','qpskber thry','bpskber prac','bpskbersim thry');
grid on;
% function for bpsk modulation
function bx=dig_mod_bpsk(bbitg)
for i=1:length(bbitg)
    if (bbitg(i)==0)
        bx(i)=1;
    else
        bx(i)=-1;
    end
end

end
% function for bpsk demodulation
function bpskbx_cp=dig_demod_bpsk(bx_cp)
for i=1:length(bx_cp)
    if (bx_cp(i)==1)
       bpskbx_cp(i)=0;
    else
        bpskbx_cp(i)=1;
    end
end

end
% function for bpsk MLdetection
function bx_cp=MLdetcbpsk(by)
         
             for i=1:length(by)
             d1=sqrt(((real(by(i))-1))^2+(imag(by(i)))^2);
             d2=sqrt(((real(by(i))+1))^2+(imag(by(i)))^2);
             if (d1<d2)
                bx_cp(i)=1;
             else
                bx_cp(i)=-1;
             end
             end  
    
  
end
% function to calculate avg symbol Energy of ofdm symbols with bpsk modulation
function Ebpsk_ofdm=energybpsk(bps1)
  E_ofdm=0;
  for i=1:length(bps1)
      E_ofdm=E_ofdm+(abs(bps1(i)))*(abs(bps1(i)));
  end
  Ebpsk_ofdm=E_ofdm/length(bps1);
end
% function to calculate avg symbol Energy of ofdm symbols with bpsk modulation
function Eqpsk_ofdm=energyqpsk(qps1)
  Eq_ofdm=0;
  for i=1:length(qps1)
      Eq_ofdm=Eq_ofdm+(abs(qps1(i)))*(abs(qps1(i)));
  end
  Eqpsk_ofdm=Eq_ofdm/length(qps1);
end
% function for qpsk modulation
function qx=dig_mod_qpsk(bbitg)
qx=[];
for i=1:2:length(bbitg)
        if (bbitg(i)==0 && bbitg(i+1)==0)
        qxx=0.707+1i*0.707;
    elseif (bbitg(i)==0 && bbitg(i+1)==1)
        qxx=-0.707+1i*0.707;
    elseif (bbitg(i)==1 && bbitg(i+1)==1)
        qxx=-0.707-1i*0.707;
    elseif (bbitg(i)==1 && bbitg(i+1)==0)
        qxx=0.707-1i*0.707; 
        end
        qx=[qx qxx];
end
end
% function for qpsk demodulation
function qbitg_cp=dig_demod_qpsk(qx_cp)
qbitg_cp=[];
for i=1:length(qx_cp)
    if (qx_cp(i)==0.707+1i*0.707)
            qbitgg_cp=[0 0];
    elseif (qx_cp(i)==-0.707+1i*0.707)
      qbitgg_cp=[0 1];
    elseif (qx_cp(i)==-0.707-1i*0.707)
        qbitgg_cp=[1 1];
    elseif (qx_cp(i)==0.707-1i*0.707)
        qbitgg_cp=[1 0]; 
        end
    qbitg_cp=[qbitg_cp qbitgg_cp];
end
end
% function for qpsk MLdetection
function qx_cp=MLdetcqpsk(qps2)
qx_cp=[];
    for i=1:length(qps2)
         d1=sqrt((real(qps2(i))-0.707)^2+(imag(qps2(i))-0.707)^2);
         d2=sqrt((real(qps2(i))+0.707)^2+(imag(qps2(i))-0.707)^2);
         d3=sqrt((real(qps2(i))+0.707)^2+(imag(qps2(i))+0.707)^2);
         d4=sqrt((real(qps2(i))-0.707)^2+(imag(qps2(i))+0.707)^2);
         x=[d1 d2 d3 d4];
         min_dis=min(x);
         if (min_dis==d1)
             qxx_cp=0.707+1i*0.707;
         elseif (min_dis==d2)
             qxx_cp=-0.707+1i*0.707;
          elseif (min_dis==d3)
             qxx_cp=-0.707-1i*0.707;
           elseif (min_dis==d4)
             qxx_cp=0.707-1i*0.707;
         end
         qx_cp=[qx_cp qxx_cp];
    end
end


