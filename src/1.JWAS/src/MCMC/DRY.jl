################################################################################
# Pre-Check
################################################################################
function errors_args(mme,methods,Pi)
    if methods == "conventional (no markers)" && mme.M!=0
        error("Conventional analysis runs without genotypes!")
    end
    if mme.M!=0 && methods=="GBLUP" && mme.M.genetic_variance == false
        error("Please provide values for the genetic variance for GBLUP analysis")
    end
    if mme.nModels > 1 && mme.M!=0
        if Pi != 0.0 && round(sum(values(Pi)),digits=2)!=1.0
          error("Summation of probabilities of Pi is not equal to one.")
        end
    end
end

function check_pedigree(mme,df,pedigree)
    if mme.ped == 0 && pedigree == false
        return
    end
    if pedigree!=false
        pedID=map(string,collect(keys(pedigree.idMap)))
    else
        pedID=map(string,collect(keys(mme.ped.idMap)))
    end

    if mme.M!=0 && !issubset(mme.M.obsID,pedID)
        error("Not all genotyped individuals are found in pedigree!")
    end

    phenoID = map(string,df[1])
    if !issubset(phenoID,pedID)
        error("Not all phenotyped individuals are found in pedigree!")
    end
end

function check_outputID(outputEBV,mme)
    #Genotyped individuals are usaully not many, and are used in GWAS (complete
    #and incomplete), thus are used as default output_ID if not provided
    if outputEBV == false
        mme.output_ID = 0
    elseif mme.output_ID == 0 && mme.M != 0
        mme.output_ID = mme.M.obsID
    elseif mme.output_ID == 0 && mme.M == 0 && mme.pedTrmVec != 0
        #output EBV for all individuals in the pedigree for PBLUP
        pedID=map(String,collect(keys(mme.ped.idMap)))
        mme.output_ID = pedID
    end
end

function check_phenotypes(mme,df,single_step_analysis=false)
    phenoID = map(string,df[1])#same to df[:,1] in deprecated CSV
    if mme.M == 0
        return
    end
    if single_step_analysis == false
        if !issubset(phenoID,mme.M.obsID)
            printstyled("Phenotyped individuals are not a subset of\n",
            "genotyped individuals (complete genomic data,non-single-step).\n",
            "Only use phenotype information for genotyped individuals.\n",bold=false,color=:red)
            index = [phenoID[i] in mme.M.obsID for i=1:length(phenoID)]
            df    = df[index,:]
        elseif mme.output_ID!=0 && !issubset(mme.output_ID,mme.M.obsID)
            printstyled("Testing individuals are not a subset of \n",
            "genotyped individuals (complete genomic data,non-single-step).\n",
            "Only output EBV for tesing individuals with genotypes.\n",bold=false,color=:red)
            mme.output_ID = intersect(mme.output_ID,mme.M.obsID)
        end
    else
        pedID = map(string,collect(keys(mme.ped.idMap)))
        if !issubset(phenoID,pedID)
            printstyled("Phenotyped individuals are not a subset of\n",
            "individuals in pedigree (incomplete genomic data (single-step) or PBLUP).\n",
            "Only use phenotype information for individuals in the pedigree.\n",bold=false,color=:red)
            index = [phenoID[i] in pedID for i=1:length(phenoID)]
            df    = df[index,:]
        elseif mme.output_ID!=0 && !issubset(mme.output_ID,pedID)
            printstyled("Testing individuals are not a subset of \n",
            "individuals in pedigree (incomplete genomic data (single-step) or PBLUP).\n",
            "Only output EBV for tesing individuals in the pedigree.\n",bold=false,color=:red)
            mme.output_ID = intersect(mme.output_ID,pedID)
        end
    end
end

function init_mixed_model_equations(mme,df,sol)
    getMME(mme,df)
    #starting value for sol can be provided
    if sol == false #no starting values
        sol = zeros(size(mme.mmeLhs,1))
    else            #besure type is Float64
        sol = map(Float64,sol)
    end
    return sol,df
end
