# 基于图像拼接技术实现 A look into the Past

### 成员及分工

+ 张啸天 PB18000391
  + 文献阅读 + 代码调试
+ 池子韬 PB18051145
  + 素材采集 + 实验报告撰写

### 问题描述

+ 第一类需求：混合同一场景不同时段的照片。
+ 第二类需求：将同一场景的两张局部照片进行拼接。


### 原理分析

以上两类需求均可基于图像拼接技术满足。我们根据Matthew Brown (2005) 描述的方法，分别实现了不同时图像的混合和邻接取景的图像拼接。

+ 特征点捕捉 (Interest Point Detection)

首先，将两张输入图片转换为灰度图像，对图像做σ=1的高斯模糊。

之后寻找Harris关键点。用sobel算子计算图像在x、y两个方向亮度的梯度，用σ=1.5的高斯函数对梯度做平滑处理，减小噪点对亮度的影响。很容易发现，只有在关键点附近，轻微的移动窗口都会强烈改变亮度的累加值。

通过比较矩阵的特征值，我们可以判断该点所处的状态。若l1和l2近似但值很大，表示该点位于关键点。根据Harris and Stephens (1988) 的介绍，我们并不需要直接计算两个特征值，用R = Det(H)/Tr(H)2的值就可以反映两个特征值的比值，这样可以减少运算量。我们保留R > 2的点。除此之外，每个点的R和周围8邻域像素的R值比较，仅保留局部R值最大的点。最后，去除图片边界附近的关键点。

+ 自适应非极大值抑制 (Adaptive Non-Maximal Suppression)

由于上一步得到的关键点很多，直接计算会导致很大的运算量，也会增加误差。接下去就要去除其中绝大部分的关键点，仅保留一些特征明显点，且让关键点在整幅图像内分布均匀。我们使用Matthew发明的adaptive non-maximal suppression (ANMS) 方法来择优选取特定数量的关键点。实际计算时，设定每幅图像各提取500个关键点。

+ 关键点的描述 (Feature Descriptor)

关键点的描述方法有很多种，包括局部梯度描述、尺度不变特征变换 (SIFT、SUFT) 等等。因为图像基本无旋转角度，所以这里不考虑关键点的旋转不变性。
对图像做适度的高斯模糊，以关键点为中心，取40x40像素的区域。将该区域降采样至8x8的大小，生成一个64维的向量。对向量做归一化处理。每个关键点都用一个64维的向量表示，于是每幅图像分别得到了一个500x64的特征矩阵。

+ 关键点的匹配

首先，从两幅图片的500个特征点中筛选出配对的点。筛选的方法是先计算500个特征点两两之间的欧氏距离，按照距离由小到大排序。通常情况下选择距离最小的一对特征向量配对。Lowe（2004）认为，仅仅观察最小距离并不能有效筛选配对特征点，而用最小的距离和第二小的距离的比值可以很好的进行筛选。 使用距离的比值能够获得更高的true positive， 同时控制较低的false positive。我们使用的阈值是r1/r2<0.5。

关键点的匹配使用Random Sample Consensus (RANSAC) 算法。以一幅图像为基准，每次从中随机选择8个点，在另一幅图像中找出配对的8个点。用8对点计算得到一个homography，将基准图中剩余的特征点按照homography变换投影到另一幅图像，统计配对点的个数。

重复上述步骤2000次，得到准确配对最多的一个homography。至此，两幅图像的投影变换关系已经找到。

+ 新图像的合成

在做图像投影前，要先新建一个空白画布。比较投影后两幅图像的2维坐标的上下左右边界，选取各个方向边界的最大值作为新图像的尺寸。同时，计算得到两幅图像的交叉区域.
在两幅图像的交叉区域，按照cross dissolve的方法制作两块蒙版，3个通道的像素值再次区间内递减（递升）.

### 代码实现
+ 在此仅说明工程文件中各个函数功能，具体代码详见代码文件。

ada_nonmax_suppression.m：自适应非极大值抑制

blend.m：合成新图像

dist2.m：计算特征点的欧氏距离

getFeatureDescriptor.m：描述关键点

getHomographyMatrix.m：计算两幅图像的投影变换关系

getNewSize.m：计算合成后图像尺寸

harris.m：寻找harris关键点

image_stitching.m：读取输入图片

ransacfithomography.m：使用RANSAC算法匹配关键点
### 效果展示

为了同时获得满足开头提到的两类需求的素材，且考虑到取景的困难程度和图像的稳定性，我们选择游戏《原神》中的场景进行拍摄，整理分出两类输入图像集.

set1分别对三个时间段的望舒客栈进行取景：白天、黄昏和黑夜.以下为这三张图像两两混合后的结果.

<table>
    <tr>
        <td ><center><img src="./result/dawn_night.jpg" >黄昏-黑夜</center></td>
    </tr>
</table>

<table>
    <tr>
        <td ><center><img src="./result/dawn_noon.jpg" >黄昏-白天</center></td>
    </tr>
</table>

<table>
    <tr>
        <td ><center><img src="./result/noon_dawn.jpg" >白天-黄昏</center></td>
    </tr>
</table>

<table>
    <tr>
        <td ><center><img src="./result/noon_night.jpg" >白天-黑夜</center></td>
    </tr>
</table>


set2为在璃月某地进行环绕拍摄取景。以下为几组素材拼接后的结果。

<table>
    <tr>
        <td ><center><img src="./result/1_2.jpg" >1-2</center></td>
    </tr>
</table>

<table>
    <tr>
        <td ><center><img src="./result/2_3.jpg" >2-3</center></td>
    </tr>
</table>


### 工程结构

|-project

​		|-- ada_nonmax_suppression.m

​		|-- blend.m

​		|-- dist2.m

​		|-- getFeatureDescriptor.m

​		|-- getHomographyMatrix.m

​		|-- getNewSize.m

​		|-- harris.m

​		|-- image_stitching.m

​		|-- ransacfithomography.m

### 运行说明

在MATLAB中包含各个函数文件，执行函数"image_stitching(input_A, input_B)"即可生成图片.其中input_A和input_B为待合成图像文件名；A为会发生扭曲，B则不需要扭曲.
