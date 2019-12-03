// Generated by CoffeeScript 2.4.1
(function() {
  angular.module('lm.quotas', ['core', 'lm.common']);

}).call(this);

// Generated by CoffeeScript 2.4.1
(function() {
  angular.module('lm.quotas').config(function($routeProvider) {
    $routeProvider.when('/view/lm/quotas', {
      controller: 'LMQuotasController',
      templateUrl: '/lmn_quotas:resources/partial/index.html'
    });
    return $routeProvider.when('/view/lm/quotas-disabled', {
      templateUrl: '/lmn_quotas:resources/partial/disabled.html'
    });
  });

  angular.module('lm.quotas').controller('LMQuotasApplyModalController', function($scope, $http, $uibModalInstance, $window, gettext, notify) {
    $scope.logVisible = true;
    $scope.isWorking = true;
    $http.get('/api/lm/quotas/apply').then(function() {
      $scope.isWorking = false;
      return notify.success(gettext('Update complete'));
    }).catch(function(resp) {
      notify.error(gettext('Update failed'), resp.data.message);
      $scope.isWorking = false;
      return $scope.logVisible = true;
    });
    return $scope.close = function() {
      $uibModalInstance.close();
      return $window.location.reload();
    };
  });

  angular.module('lm.quotas').controller('LMQuotasController', function($scope, $http, $uibModal, $location, $q, gettext, lmEncodingMap, notify, pageTitle, lmFileBackups) {
    pageTitle.set(gettext('Quotas'));
    //# TODO
    // Quota for class
    // Quota for project
    $scope.toChange = {
      'teacher': {},
      'student': {},
      'schooladministrator': {}
    };
    $scope._ = {
      addNewSpecial: null
    };
    $scope.searchText = gettext('Search user by login, firstname or lastname (min. 3 chars)');
    // Need an array to keep the order ...
    $scope.quota_types = [
      {
        'type': 'quota_default_global',
        'name': gettext('Quota default global (MiB)')
      },
      {
        'type': 'quota_default_school',
        'name': gettext('Quota default school (MiB)')
      },
      {
        'type': 'cloudquota_percentage',
        'name': gettext('Cloudquota (%)')
      },
      {
        'type': 'mailquota_default',
        'name': gettext('Mailquota default (MiB)')
      }
    ];
    $scope.groupquota_types = [
      {
        'type': 'linuxmuster-global',
        'classname': gettext('Quota default global (MiB)'),
        'projname': gettext('Add to default global (MiB)')
      },
      {
        'type': 'default-school',
        'classname': gettext('Quota default school (MiB)'),
        'projname': gettext('Add to default school (MiB)')
      },
      {
        'type': 'mailquota',
        'classname': gettext('Mailquota default (MiB)'),
        'projname': gettext('Add to mailquota (MiB)')
      }
    ];
    $scope.groupquota = 0;
    $scope.get_class_quota = function() {
      if (!$scope.groupquota) {
        return $http.get('/api/lm/group-quotas').then(function(resp) {
          $scope.groupquota = resp.data;
          return console.log(resp.data.project);
        });
      }
    };
    $http.get('/api/lm/quotas').then(function(resp) {
      $scope.non_default = resp.data[0];
      return $scope.settings = resp.data[1];
    });
    $scope.$watch('_.addNewSpecial', function() {
      var user;
      if ($scope._.addNewSpecial) {
        user = $scope._.addNewSpecial;
        $scope.non_default[user.role][user.login] = {
          'QUOTA': angular.copy($scope.settings['role.' + user.role]),
          'displayName': user.displayName
        };
        return $scope._.addNewSpecial = null;
      }
    });
    $scope.isDefaultQuota = function(role, quota, value) {
      return $scope.settings[role][quota] !== value;
    };
    $scope.findUsers = function(q, role = '') {
      return $http.post("/api/lm/ldap-search", {
        role: role,
        login: q
      }).then(function(resp) {
        return resp.data;
      });
    };
    $scope.userToChange = function(role, login, quota) {
      var value;
      delete $scope.toChange[role][login + "_" + quota];
      //# Default value for a quota in sophomorix
      value = '---';
      if ($scope.non_default[role][login]['QUOTA'][quota] !== $scope.settings['role.' + role][quota]) {
        value = $scope.non_default[role][login]['QUOTA'][quota];
      }
      return $scope.toChange[role][login + "_" + quota] = {
        'login': login,
        'quota': quota,
        'value': value
      };
    };
    $scope.remove = function(role, login) {
      //# Reset all 3 quotas to default
      $scope.non_default[role][login]['QUOTA'] = angular.copy($scope.settings['role.' + role]);
      $scope.userToChange(role, login, 'quota_default_global');
      $scope.userToChange(role, login, 'quota_default_school');
      $scope.userToChange(role, login, 'mailquota_default');
      return delete $scope.non_default[role][login];
    };
    $scope.saveApply = function() {
      return $http.post('/api/lm/quotas', {
        toChange: $scope.toChange
      }).then(function() {
        return $uibModal.open({
          templateUrl: '/lmn_quotas:resources/partial/apply.modal.html',
          controller: 'LMQuotasApplyModalController',
          backdrop: 'static'
        });
      });
    };
    return $scope.backups = function() {
      return lmFileBackups.show('/etc/linuxmuster/sophomorix/user/quota.txt');
    };
  });

}).call(this);

