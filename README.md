# LakeTrophic

This project works on estimating the lake trophic state of CT lakes using various models.

* [Modeling lake trophic state: A random forest approach (Hollister et al. 2016)](https://doi.org/10.1002/ecs2.1321)
* [Northeast Lake and Pond Classification (Olivero-Sheldon & Anderson. 2016)](https://easterndivision.s3.amazonaws.com/Freshwater/Lakes/Northeast%20Lake%20and%20Pond%20Classification.pdf)

## Methods
- Using source code from the studies, created a random forest object from each study trained using the respective datasets
- Created two different spreadsheet templates for running new lake data in the models
- Created a script that reformats the spreadsheet template with lake data to run in each of the models
  * Runs the models with new data
  * Creates and merges tables of predicted trophic state of each input lake

