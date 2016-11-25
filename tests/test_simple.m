function test_suite=test_simple
% probability uniformity tests for cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_skip_ci
    is_running_ci=~isempty(getenv('CI'));
    if is_running_ci
        reason=['Running coverage on CI platform for a very slow '...
                        'function, which may lead to a stalled build. '];
                cosmo_notify_test_skipped(reason);
    end
    
    error('this should fail');
    
    

function test_skip_ci_mocov
    is_running_ci=~isempty(getenv('CI'));
    if is_running_ci
        stack=dbstack();
        names={stack.name};

        is_running_MoCov_coverage=any(cosmo_match({'mocov'},names));
        if is_running_MoCov_coverage
            reason=['Running coverage on CI platform for a very slow '...
                        'function, which may lead to a stalled build. '];

            cosmo_notify_test_skipped(reason);
            return;
        end
    end
    
    error('this should fail');
    
    
