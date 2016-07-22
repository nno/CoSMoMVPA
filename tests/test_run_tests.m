function test_suite = test_run_tests
% tests for cosmo_run_tests
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_run_tests_passing
    test_content='assert(true);';
    [result,output]=helper_test_make_and_run(test_content);
    assertTrue(result);
    assert(~isempty(findstr('OK',output)));


function test_run_tests_failing
    test_content='assert(false);';
    [result,output]=helper_test_make_and_run(test_content);
    assertFalse(result);
    assert(~isempty(findstr('FAILED',output)));

function test_run_tests_no_file_found_absolute_path()
    cosmo_test_dir=fileparts(mfilename('fullpath'));
    fn=cosmo_make_temp_filename(fullfile(cosmo_test_dir,'test_'),'.m');
    % this is for debugging, should raise an exception
    helper_run_tests({fn})
    %assertExceptionThrown(@()helper_run_tests({fn}),'');


function test_run_tests_no_file_found_relative_path()
    fn=cosmo_make_temp_filename('test_','.m');
    assertExceptionThrown(@()helper_run_tests({fn}),'');


function test_run_tests_missing_logfile_argument()
    assertExceptionThrown(@()helper_run_tests({'-logfile'}),'');


function [result,output]=helper_test_make_and_run(test_content)
    cosmo_test_dir=fileparts(mfilename('fullpath'));

    fn=cosmo_make_temp_filename(fullfile(cosmo_test_dir,'test_'),'.m');

    [unused,test_name]=fileparts(fn);

    fid=fopen(fn,'w');
    cleaner=onCleanup(@()delete(fn));
    fprintf(fid,...
            ['function test_suite=%s\n',...
            'initTestSuite;\n',...
            'function %s_generated\n'...
            '%s'],...
            test_name,test_name,test_content);
    fclose(fid);


    args={fn};
    [result,output]=helper_run_tests(args);




function [result,output]=helper_run_tests(args)
    warning_state=cosmo_warning();
    orig_path=path();
    orig_pwd=pwd();
    log_fn=tempname();

    disp('state');
    disp({warning_state,orig_path,orig_pwd,log_fn});

    cleaner=onCleanup(@()run_sequentially({...
                            @()path(orig_path),...
                            @()cosmo_warning(warning_state),...
                            @()cd(orig_pwd),...
                            @()delete_if_exists(log_fn)}));

    % ensure path is set; disable warnings by cosmo_set_path
    cosmo_warning('off');

    more_args={'-verbose','-logfile',log_fn,'-no_doctest'};
    disp('before running tests');
    disp(more_args);
    disp(args);
    result=cosmo_run_tests(more_args{:},args{:});
    disp('result');
    disp(result);
    fid=fopen(log_fn);
    disp('open file');
    output=fread(fid,Inf,'char=>char')';
    disp('output');
    disp(output);


function run_sequentially(cell_with_funcs)
    n=numel(cell_with_funcs);
    for k=1:n
        func=cell_with_funcs{k};
        disp('Running seq');
        disp(func);
        func();
        disp('Running done');
    end

function delete_if_exists(fn)
    disp('deleting if exist');
    disp(fn);
    if exist(fn,'file')
        disp('here');
        delete(fn);
        disp('deleted');
    end
