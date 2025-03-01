
# Hidden Markov Model - Viterbi Training

The main file to run the parameter optimization and Viterbi Training is the "ARHMM_Viterbi_NV.m" script. You can simple open the script and run it. The script also handles the data reading at the beginning. The script saves the last parametes you optimized and if you set "isContinueLearning" to 1, it can continue the optimization from the last run. The last run is saved as "lastSolution[lastSaveSuffix].mat" that "lastSaveSuffix" is the name of a variable at the beginning of the code that needs to be changed for another dataset to avoid overwriting the checkpoint for another dataset.


The Viterbi Training and related dynamic programming table is implemented in "inference_Viterbi_NV.m" function file. This function is called by "ARHMM_Viterbi_NV.m" script.

After obtaining the parameters, you can generate new data by running "test_SR.m" script. The script requires hard-coded parameters.

"tvd_mm.m" is third-party function that smooths the input data. Please refer to the file to learn about the author(s) and related research work.

