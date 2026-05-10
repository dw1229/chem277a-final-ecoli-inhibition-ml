##### Please change the full ANN method section with this one: 

**5. Artificial neural network**

A feedforward neural network (Multi-Layer Perceptron) with one hidden layer of 64 ReLU units and a softmax output over two classes was implemented in TensorFlow/Keras, trained with the Adam optimizer and categorical cross-entropy loss. The baseline model showed severe overfitting (training loss collapsed to near zero while validation loss climbed) and limited recall on the active class (0.49). A progressive regularization study was therefore conducted, with each variant evaluated against the previous configuration: L2 weight decay (lambda = 0.01) combined with EarlyStopping (patience = 10) to address overfitting; balanced class weights (9:1, with 12:1 also tested for sensitivity) to push the model toward the minority active class; SMOTE-based synthetic minority oversampling (Chawla et al. 2002) as a data-level alternative to loss reweighting; threshold tuning to characterize the precision-recall trade-off across operating points (Esposito et al. 2021); and a two-hidden-layer variant (64 then 32 neurons with dropout = 0.3 and 0.2 between layers) to test whether added depth captures more nonlinear structure once SMOTE expands the effective training set. The literature informing these choices includes the QSAR class-imbalance work of Tomei et al. (2025), de Souza et al. (2023), and Koutsoukas et al. (2017), the Goodfellow et al. (2016) treatment of regularization in deep learning, and the TensorFlow regularization guide.


#### let's add a branch underneat as 5.a

## Further ANN Exploration: SMOTE Oversampling and Architecture Depth

Version 3 (L2 + EarlyStopping + class weights at 9x) achieved 92% accuracy and 63% recall on the active class, the strongest of the V1–V4 series. The next set of experiments explores two further questions raised by that result.

First, class weighting addresses imbalance by reweighting the loss function during training; an alternative approach is to address it at the data level by oversampling the minority class with synthetic examples. SMOTE (Chawla et al. 2002) generates new active compounds by interpolating in feature space between existing actives, so it expands the effective training set rather than re-weighting the same compounds. We test whether this data-level approach improves on the loss-level approach used in V3.

Second, with SMOTE doubling the effective training set size from 3,414 to 6,144 examples, the network has sufficient signal to support a deeper architecture without overfitting. We test whether a two-hidden-layer variant (64 → 32 neurons with dropout) captures additional nonlinear structure that the single-layer model cannot.

The following sections progress through: a regularized ANN with dropout and class weights as a direct extension of V3; threshold tuning and ROC analysis on that model; PR-AUC analysis given the heavy class imbalance; the SMOTE oversampling variant; and the two-layer SMOTE variant proposed as the final ANN configuration.



**Discussion for ANN Improvements (SMOTE Oversampling and Two-Layer Architecture)**

Two further variants were explored to test whether the ANN's minority-class performance could be improved beyond what class weighting alone provided.

The first variant replaces class weighting with SMOTE-based synthetic minority oversampling (Chawla et al. 2002), motivated by the difference between loss-level and data-level approaches to imbalance. Class weighting tells the model to count active-class mistakes more heavily but does not change what the model sees during training; SMOTE expands the effective training set by interpolating between existing actives to generate diverse synthetic examples. The intuition is that giving the network more minority-class examples to learn from, rather than re-weighting the same examples, should produce smoother decision boundaries around the active region of feature space. Compared to the class-weighted variant, the SMOTE configuration improved nearly every metric: F1 on actives rose from 0.578 to 0.637, precision from 0.553 to 0.689, ROC-AUC from 0.886 to 0.901, and PR-AUC from 0.673 to 0.698. Recall on actives stayed essentially flat (0.605 to 0.593), so the gain came from substantially fewer false positives rather than catching more true actives. This is consistent with the QSAR class-imbalance literature, which generally finds synthetic oversampling to provide more effective training signal than loss reweighting for bioassay data.

The second variant uses SMOTE's expanded training set to support a deeper architecture: a two-hidden-layer network (64 then 32 ReLU units) with dropout between layers (0.3 and 0.2). With the original 3,414 training samples and 1,037 features, a deeper network would almost certainly overfit; SMOTE roughly doubles the effective training set, providing enough signal to justify the added capacity. Koutsoukas et al. (2017) identified the number of hidden layers among the most critical hyperparameters for bioactivity prediction tasks, supporting the depth experiment. The two-layer SMOTE configuration improved further on the single-layer SMOTE variant on F1 (0.643 vs 0.637) and on recall on actives (0.628 vs 0.593), with comparable accuracy (0.930 vs 0.932) and ROC-AUC (0.904 vs 0.901). Training and validation losses tracked closely throughout training, confirming that the regularization stack effectively constrained the deeper network without re-introducing the overfitting that plagued the V1 baseline. This variant strictly improves over the V1 baseline on every minority-class metric and adds threshold-free metrics (ROC-AUC and PR-AUC) that the baseline did not provide.

Threshold tuning was also performed on the regularized ANN to characterize the precision-recall trade-off across operating points (Esposito et al. 2021). At the default threshold of 0.50 the model favors recall on the active class (0.605 with precision 0.553); at the F1-optimal threshold of 0.78 the model favors precision (0.723 with recall 0.547). The ROC-AUC of 0.886 confirms the classifier is well-calibrated across thresholds, so the choice of operating point is a downstream-application question rather than a model-quality question. For primary screening, where recovering as many true actives as possible matters more than false-positive cost, the lower threshold is preferred. For hit-list confirmation, where false positives carry more cost, the higher threshold is preferred. Reporting both rather than picking one was a deliberate choice, since the optimal operating point depends on how the predictions feed into subsequent experimental work.



## References

Bjerrum, E. J. (2017). SMILES enumeration as data augmentation for neural network modeling of molecules. *arXiv preprint arXiv:1703.07076*. https://arxiv.org/abs/1703.07076

Blaskovich, M. A. T., Zuegg, J., Elliott, A. G., & Cooper, M. A. (2015). Helping chemists discover new antibiotics. *ACS Infectious Diseases*, 1(7), 285–287. https://doi.org/10.1021/acsinfecdis.5b00044

Chawla, N. V., Bowyer, K. W., Hall, L. O., & Kegelmeyer, W. P. (2002). SMOTE: Synthetic Minority Over-sampling Technique. *Journal of Artificial Intelligence Research*, 16, 321–357. https://doi.org/10.1613/jair.953

Cherkasov, A., Muratov, E. N., Fourches, D., Varnek, A., Baskin, I. I., Cronin, M., ... & Tropsha, A. (2014). QSAR modeling: Where have you been? Where are you going to? *Journal of Medicinal Chemistry*, 57(12), 4977–5010. https://doi.org/10.1021/jm4004285

Davis, J., & Goadrich, M. (2006). The relationship between Precision-Recall and ROC curves. In *Proceedings of the 23rd International Conference on Machine Learning* (pp. 233–240). https://doi.org/10.1145/1143844.1143874

de Souza, J. E., Pontes, F. J. S., et al. (2023). Resampling strategies for imbalanced datasets in QSAR classification: A comparative study. *Journal of Molecular Graphics and Modelling*, 122, 108472.

Esposito, C., Landrum, G. A., Schneider, N., Stiefl, N., & Riniker, S. (2021). GHOST: Adjusting the decision threshold to handle imbalanced data in machine learning. *Journal of Chemical Information and Modeling*, 61(6), 2623–2640. https://doi.org/10.1021/acs.jcim.1c00160

Goodfellow, I., Bengio, Y., & Courville, A. (2016). *Deep Learning* (Chapter 7: Regularization for Deep Learning). MIT Press. https://www.deeplearningbook.org/contents/regularization.html

Koutsoukas, A., Monaghan, K. J., Li, X., & Huan, J. (2017). Deep-learning: Investigating deep neural networks hyper-parameters and comparison of performance to shallow methods for modeling bioactivity data. *Journal of Cheminformatics*, 9(1), 42. https://doi.org/10.1186/s13321-017-0226-y

Landrum, G. (2006). RDKit: Open-source cheminformatics. https://www.rdkit.org

McInnes, L., Healy, J., & Melville, J. (2018). UMAP: Uniform Manifold Approximation and Projection for dimension reduction. *arXiv preprint arXiv:1802.03426*. https://arxiv.org/abs/1802.03426

Murray, C. J. L., Ikuta, K. S., Sharara, F., Swetschinski, L., Aguilar, G. R., Gray, A., ... & Naghavi, M. (2022). Global burden of bacterial antimicrobial resistance in 2019: A systematic analysis. *The Lancet*, 399(10325), 629–655. https://doi.org/10.1016/S0140-6736(21)02724-0

O'Neill, J. (2016). *Tackling drug-resistant infections globally: Final report and recommendations*. The Review on Antimicrobial Resistance. https://amr-review.org/

Rogers, D., & Hahn, M. (2010). Extended-connectivity fingerprints. *Journal of Chemical Information and Modeling*, 50(5), 742–754. https://doi.org/10.1021/ci100050t

TensorFlow. (n.d.). *Classification on imbalanced data*. TensorFlow tutorials. https://www.tensorflow.org/tutorials/structured_data/imbalanced_data

Tomei, V., et al. (2025). Class imbalance handling for QSAR-based antimicrobial activity prediction: A systematic comparison. *Scientific Reports*, 15.

Tommasi, R., Brown, D. G., Walkup, G. K., Manchester, J. I., & Miller, A. A. (2015). ESKAPEing the labyrinth of antibacterial discovery. *Nature Reviews Drug Discovery*, 14(8), 529–542. https://doi.org/10.1038/nrd4572
