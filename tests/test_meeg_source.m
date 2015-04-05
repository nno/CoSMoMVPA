
function test_suite=test_meeg_source()
    initTestSuite;

function test_meeg_dataset()
    tps={'freq_pow','time_mom','rpt_trial_mom',...
                        'rpt_trial_pow'};
    for j=1:numel(tps)
        [ft,fdim,data_label]=generate_ft_source(tps{j});
        ds=cosmo_meeg_dataset(ft);

        % check fdim
        assertEqual(ds.a.fdim,fdim);

        key=data_label{1};
        sub_key=data_label{2};

        ft_first_sample_all=ft.(key).(sub_key);
        ft_first_sample=ft_first_sample_all(ft.inside,:);

        switch sub_key
            case 'mom'
                % choose a random sensor
                inside_idxs=find(ft.inside);
                pos=ceil(rand()*numel(inside_idxs));
                inside_idx=inside_idxs(pos);
                assertEqual(ds.samples(1,ds.fa.pos==inside_idx),...
                                        ft_first_sample{pos}(:)')

            otherwise
                assertEqual(ds.samples(1,:),ft_first_sample(:)');
        end

        [ft_arr, ft_labels, ft_values]=cosmo_unflatten(ds,2,...
                                            'matrix_labels','pos');


        assertEqual(ft_arr(ft_arr~=0),ds.samples(:));
        assertEqual(ft_labels, fdim.labels);
        assertEqual(ft_values, fdim.values);

        % select single element, and ensure it is the same in the
        % fieldtrip struct as in the dataset struct
        dim_sizes=cellfun(@(x)size(x,2),fdim.values);
        ndim=numel(dim_sizes);
        rp=ceil(rand(1,ndim).*dim_sizes(:)');
        [nsamples,nfeatures]=size(ds.samples);
        ds_msk=false(1,nfeatures);
        ft_idx=cell(1,1+ndim);
        ft_idx{1}=randperm(nsamples);
        for k=1:ndim
            dim_label=fdim.labels{k};
            ds_msk = ds_msk | rp(k)~=ds.fa.(dim_label);

            switch dim_label
                case 'mom'
                    ft_idx{k+1}=rp(k);

                case 'pos'
                    ft_values=ft.(dim_label);
                    ft_idx{k+1}=find(all(bsxfun(@eq,...
                                    ft_values(rp(k),:),ft_values),2));

                otherwise
                    ft_values=ft.(dim_label);
                    ft_idx{k+1}=find(ft_values(rp(k))==ft_values);
            end
        end

        ds_sel=cosmo_slice(cosmo_slice(ds,~ds_msk,2),ft_idx{1});
        ft_sel=ft_arr(ft_idx{:});

        if ft_sel==0
            assertTrue(isempty(ds_sel.samples));
        else
            assertEqual(ds_sel.samples,ft_sel);
        end



        %re-order features
        nfeatures=size(ds.samples,2);
        ds2=cosmo_slice(ds,randperm(nfeatures),2);

        ft2=cosmo_map2meeg(ds2);
        assertEqual(ft,ft2);

        if j==1
            % test compatibility with old fieldtrip

            ft2.inside=find(ft2.inside);
            ds3=cosmo_meeg_dataset(ft2);
            assertEqual(ds,ds3);

            ft2.inside=struct();
            assertExceptionThrown(@()cosmo_meeg_dataset(ft2),'');
        end


    end


function test_meeg_fmri_dataset()
    ds=cosmo_synthetic_dataset('type','source');
    ds_fmri=cosmo_fmri_dataset(ds);
    ft=cosmo_map2meeg(ds);
    ds_ft_fmri=cosmo_fmri_dataset(ft);

    ds_vol=cosmo_vol_grid_convert(ds,'tovol');
    assertEqual(ds_vol,ds_fmri);

    assertTrue(isempty(fieldnames(ds_ft_fmri.sa)))
    ds_vol=rmfield(ds_vol,'sa');
    ds_ft_fmri=rmfield(ds_ft_fmri,'sa');
    assertEqual(ds_vol,ds_ft_fmri);



function [ft,fdim,data_label]=generate_ft_source(tp)
    ft=struct();
    dim_pos_range={-3:3,-4:4,-5:5};
    nsamples=2;
    freq=[3 5 7 9];
    time=[-1 0 1 2];
    mom_labels={'x','y','z'};

    ft.dim=cellfun(@numel,dim_pos_range);
    ft.pos=cosmo_cartprod(dim_pos_range);
    ft.inside=sum(ft.pos.^2,2)<30;

    fdim=struct();

    switch tp
        case 'freq_pow'
            ft.freq=freq;
            ft.method='average';
            ft.avg=generate_data(ft.inside,numel(freq),1,'pow');
            fdim.labels={'pos';'freq'};
            fdim.values={ft.pos';freq(:)'};
            data_label={'avg','pow'};

        case 'time_mom'
            ft.time=time;
            ft.method='average';
            ft.avg=generate_data(ft.inside,numel(time),1,'mom');
            fdim.labels={'pos';'mom';'time'};
            fdim.values={ft.pos';mom_labels;time(:)'};
            data_label={'avg','mom'};


        case 'rpt_trial_pow';
            ft.time=time;
            ft.method='rawtrial';
            ft.trial=generate_data(ft.inside,numel(time),nsamples,'pow');
            fdim.labels={'pos';'time'};
            fdim.values={ft.pos';time(:)'};
            data_label={'trial','pow'};

        case 'rpt_trial_mom';
            ft.time=time;
            ft.method='rawtrial';
            ft.trial=generate_data(ft.inside,numel(time),nsamples,'mom');
            fdim.labels={'pos';'mom';'time'};
            fdim.values={ft.pos';mom_labels;time(:)'};
            data_label={'trial','mom'};

        otherwise
            error('unsupported type %s', tp);

    end


function d=generate_data(inside,nfeatures,nsamples,fld)
    is_single_trial=nargin<3;

    if is_single_trial
        nsamples=1;
    end

    switch fld
        case 'mom'
            d=generate_mom(inside,nfeatures,nsamples);
        case 'pow'
            d=generate_pow(inside,nfeatures,nsamples);
        otherwise
            error('not supported: %s', fld);
    end


function all_trials=generate_pow(inside,nfeatures,nsamples)
    nf=numel(inside);
    ni=sum(inside);

    all_data=NaN(nf,nfeatures);
    trial_data=cosmo_rand(ni,nfeatures);

    all_trials_cell=cell(nsamples,1);
    for j=1:nsamples
        data=all_data;
        data(inside,:)=trial_data+j;
        all_trials_cell{j}.pow=data;
    end

    all_trials=cat(1,all_trials_cell{:})';


function all_trials=generate_mom(inside,nfeatures,nsamples)
    nf=numel(inside);
    i=find(inside);
    ni=numel(i);

    data=cosmo_rand(3,nfeatures,ni);

    all_trials_cell=cell(1,nsamples);
    for j=1:nsamples
        one_trial=cell(nf,1);
        for k=1:ni
            one_trial{i(k)}=data(:,:,k)+j;
        end
        all_trials_cell{j}=one_trial;
    end

    all_trials=struct('mom',all_trials_cell);






