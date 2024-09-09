仅使用time_harp 260测试过：
文件类型简介：
.ptu:通过picoquant上位机软件采集的T2和T3模式数据，该文件为按照一定格式存储的二进制文件；
.phu:通过picoquant上位机软件采集的直方图模式数据，该文件为按照一定格式存储的二进制文件。
.out:将上位机软件采集的数据进一步处理，该文件数据可以直接读取。
.mat:为matlab可以直接读取的文件，使用matlab对数据进行了一些处理，比如去除了空白数据和转换为散点图等。


T2_process文件夹：用于T2数据的离线处理
multi_PTU2outfile.m  将多个.ptu文件转换为.out文件；
multi_T2_outfile2mat.m 将多个.out文件转换为.mat文件，可直接绘制为散点图；

Single_T2_outfile2mat.m 为将单个.out文件转换为.mat文件，可直接绘制为散点图；

multi_T2_2_mat.m （多合一）将多个.ptu文件直接转换为.mat文件，需要包含子函数multi_PTU2outfile.m；
multi_PTU2outfile.m 为将多个.out文件转换为.mat文件子函数；


