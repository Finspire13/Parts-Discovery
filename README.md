# Parts Discovery

**This is a re-implementation of _'Discovering the physical parts of an articulated object class from multiple videos'[1]_.**
Some changes are made when implementing. For example, only foreground superpixels are clustered in the first satge. Average IoU of this version (0.276) is better than \[1\] (0.245). 


## Shape Cut Enhencement

In addition to re-implementation, this version employs shape clues to make persicion slightly more higher. 
Object foreground masks are cut into parts according to its shape information using [2]. Then a shape constaint are added when optimization to enforce superpixels in difference cut regions to take difference labels. Shape cut dataset are provided.

## Usage

* Download dataset from [here](http://pan.baidu.com/s/1kVgaahh).
* Extract and put into corresponding folders in home directory.
* Run main.m and have fun.

## Dataset

The dataset consists of two parts. One is the original dataset from [\[1\]](http://calvin.inf.ed.ac.uk/publications/partdecomposition/) with several inconsisensy fixed and optical flow added. The other one is shape cuts dataset.

**Original dataset from [1]**

32 video sequences in four classes (horse-left, horse-right, tiger-left, tiger-right). Following data are included:

1)VIDEO FRAMES

2)SUPERPIXELS

superPixels.mat computed by [3]

3)GROUND-TRUTH PARTS ANNOTATIONS

gtLabels.mat

4)FOREGROUND SEGMENTATIONS

segments.mat computed by [4] and segments_OSVOS.mat computed by [5]

5)TEMPORAL SUPERPIXELS

temporalSuperPixels.mat computed by [3]

6)OPTICAL FLOW

opticalFlow.mat computed by [6] and flow_flownet.mat computed by [7]

Check original dataset readme file DATA_README.txt for details.

**Shape cut dataset**

Shape cuts for all frames stored in txt file.
Each row represents a cut in format of **( pointOneX pointOneY pointTwoX pointTwoY )**


## Alternative for segments, flow and superpixels
Code of [6] are provided and others are not. If you want to re-compute segments, flow or superpixels, you need to collect the code additionally.
Methods are not constained and you can choose other alternatives.

## Parameters
temporalInterval: 1~5

partsNum: Part num to find

quantizedSpace: Granularity of location model

partsRelaxation: 1~3

degeneratedClusterPenalty: 10~Inf

degeneratedClusterCriteria: 10~100

softMaskFactor: 1~3

foregroundSPCriteria: 0.1~0.9

partStrictness: 0.1~1

spatialWeight: 0~0.5

temporalWeight: 0~2

shapeWeight: -0.2~0

## Support
Any question please contact _Daochang Liu_ (finspire13@gmail.com).

## Reference

[1] Discovering the physical parts of an articulated object class from multiple videos

[2] A method of perceptual-based shape decomposition

[3] A video representation using temporal superpixels

[4] Fast object segmentation in unconstrained video

[5] One-shot video object segmentation

[6] Large displacement optical flow: descriptor matching in variational motion estimation

[7] FlowNet: Learning optical flow with convolutional networks