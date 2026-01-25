'use client';

import { useState, useEffect } from 'react';
import { getFirebaseAuth, getFirestoreClient } from '@/lib/firebase-client';
import { collection, query, limit, orderBy, getDocs, doc, getDoc, updateDoc, increment, Timestamp, serverTimestamp } from 'firebase/firestore';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import {
  Loader2,
  Search,
  User,
  Ban,
  CheckCircle,
  Coins,
  Eye,
  ChevronLeft,
  ChevronRight,
  Users,
  UserPlus,
  Calendar,
  Shield,
} from 'lucide-react';

interface User {
  uid: string;
  email: string | null;
  name: string | null;
  photo: string | null;
  coins: number;
  balance: number;
  totalCoins: number;
  referralCode: string | null;
  referralCount: number;
  isBlocked: boolean;
  blockedReason: string | null;
  joiningTimestamp: string | null;
  lastLoginTimestamp: string | null;
  country: string | null;
  userType: string | null;
  deviceId: string | null;
}

interface UserDetails extends User {
  referralEarning: number;
  countryCode: string | null;
  city: string | null;
  ipAddress: string | null;
  dailyPayoutCount: number;
  totalPayoutCount: number;
  dailyGameCount: number;
  energy: number;
  rated: boolean;
  referred: boolean;
  socialFollowed: string[];
  reviewedList: string[];
  offersEarning: number;
  rewardEarning: number;
  emailVerified: boolean;
  disabled: boolean;
  creationTime: string | null;
  lastSignInTime: string | null;
  recentTransactions: any[];
  recentRewards: any[];
  installedApps: string[] | null;
  googleUserReason: string | null;
}

export default function UserManagementPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [blockedFilter, setBlockedFilter] = useState<string>('all');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selectedUser, setSelectedUser] = useState<UserDetails | null>(null);
  const [detailsDialogOpen, setDetailsDialogOpen] = useState(false);
  const [blockDialogOpen, setBlockDialogOpen] = useState(false);
  const [grantCoinsDialogOpen, setGrantCoinsDialogOpen] = useState(false);
  const [blockReason, setBlockReason] = useState('');
  const [coinsAmount, setCoinsAmount] = useState('');
  const [grantCoinsReason, setGrantCoinsReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const getAuthToken = async (): Promise<string> => {
    const auth = getFirebaseAuth();
    const user = auth.currentUser;
    if (!user) throw new Error('Not authenticated');
    return await user.getIdToken(true);
  };

  useEffect(() => {
    fetchUsers();
  }, [page, blockedFilter, searchTerm]);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const db = getFirestoreClient();
      
      // Query Firestore directly
      let q;
      try {
        // Try ordering by joiningTimestamp
        q = query(
          collection(db, 'users'),
          orderBy('joiningTimestamp', 'desc'),
          limit(1000)
        );
      } catch (e) {
        // If orderBy fails (missing index), query without ordering
        q = query(
          collection(db, 'users'),
          limit(1000)
        );
      }
      
      const snapshot = await getDocs(q);
      
      let allUsers = snapshot.docs.map((docSnapshot) => {
        const data = docSnapshot.data();
        
        // Safely handle timestamp fields
        let joiningTimestamp: string | null = null;
        let lastLoginTimestamp: string | null = null;
        
        try {
          if (data.joiningTimestamp) {
            const ts = data.joiningTimestamp as Timestamp;
            joiningTimestamp = ts.toDate().toISOString();
          }
        } catch (e) {
          // Ignore timestamp errors
        }
        
        try {
          if (data.lastLoginTimestamp) {
            const ts = data.lastLoginTimestamp as Timestamp;
            lastLoginTimestamp = ts.toDate().toISOString();
          }
        } catch (e) {
          // Ignore timestamp errors
        }
        
        return {
          uid: docSnapshot.id,
          email: data.email || null,
          name: data.name || null,
          photo: data.photo || null,
          coins: data.coins || 0,
          balance: data.balance || 0,
          totalCoins: data.totalCoins || 0,
          referralCode: data.referralCode || null,
          referralCount: data.referralCount || 0,
          isBlocked: data.isBlocked || false,
          blockedReason: data.blockedReason || null,
          joiningTimestamp,
          lastLoginTimestamp,
          country: data.country || null,
          userType: data.userType || null,
          deviceId: data.deviceId || null,
        };
      });
      
      // Sort by joiningTimestamp if we couldn't use orderBy
      allUsers.sort((a, b) => {
        if (!a.joiningTimestamp && !b.joiningTimestamp) return 0;
        if (!a.joiningTimestamp) return 1;
        if (!b.joiningTimestamp) return -1;
        return new Date(b.joiningTimestamp).getTime() - new Date(a.joiningTimestamp).getTime();
      });
      
      // Filter by blocked status
      if (blockedFilter === 'true') {
        allUsers = allUsers.filter((user) => user.isBlocked === true);
      } else if (blockedFilter === 'false') {
        allUsers = allUsers.filter((user) => user.isBlocked === false);
      }
      
      // Filter by search term
      if (searchTerm) {
        const searchLower = searchTerm.toLowerCase();
        allUsers = allUsers.filter(
          (user) =>
            user.email?.toLowerCase().includes(searchLower) ||
            user.name?.toLowerCase().includes(searchLower) ||
            user.uid.toLowerCase().includes(searchLower) ||
            user.referralCode?.toLowerCase().includes(searchLower)
        );
      }
      
      const total = allUsers.length;
      const offset = (page - 1) * 20;
      const paginatedUsers = allUsers.slice(offset, offset + 20);
      
      setUsers(paginatedUsers);
      setTotalPages(Math.ceil(total / 20));
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchUserDetails = async (uid: string) => {
    try {
      const db = getFirestoreClient();
      const userDoc = await getDoc(doc(db, 'users', uid));
      
      if (!userDoc.exists()) {
        console.error('User not found');
        return;
      }
      
      const data = userDoc.data();
      
      // Safely handle timestamps
      let joiningTimestamp: string | null = null;
      let lastLoginTimestamp: string | null = null;
      
      try {
        if (data.joiningTimestamp) {
          const ts = data.joiningTimestamp as Timestamp;
          joiningTimestamp = ts.toDate().toISOString();
        }
      } catch (e) {}
      
      try {
        if (data.lastLoginTimestamp) {
          const ts = data.lastLoginTimestamp as Timestamp;
          lastLoginTimestamp = ts.toDate().toISOString();
        }
      } catch (e) {}
      
      const userDetails: UserDetails = {
        uid: userDoc.id,
        email: data.email || null,
        name: data.name || null,
        photo: data.photo || null,
        coins: data.coins || 0,
        balance: data.balance || 0,
        totalCoins: data.totalCoins || 0,
        referralCode: data.referralCode || null,
        referralCount: data.referralCount || 0,
        referralEarning: data.referralEarning || 0,
        isBlocked: data.isBlocked || false,
        blockedReason: data.blockedReason || null,
        joiningTimestamp,
        lastLoginTimestamp,
        country: data.country || null,
        countryCode: data.countryCode || null,
        city: data.city || null,
        userType: data.userType || null,
        deviceId: data.deviceId || null,
        ipAddress: data.ipAddress || null,
        dailyPayoutCount: data.dailyPayoutCount || 0,
        totalPayoutCount: data.totalPayoutCount || 0,
        dailyGameCount: data.dailyGameCount || 0,
        energy: data.energy || 0,
        rated: data.rated || false,
        referred: data.referred || false,
        socialFollowed: data.socialFollowed || [],
        reviewedList: data.reviewedList || [],
        offersEarning: data.offersEarning || 0,
        rewardEarning: data.rewardEarning || 0,
        emailVerified: false,
        disabled: false,
        creationTime: null,
        lastSignInTime: null,
        recentTransactions: [],
        recentRewards: [],
        installedApps: data.installedApps || null,
        googleUserReason: data.googleUserReason || null,
      };
      
      setSelectedUser(userDetails);
      setDetailsDialogOpen(true);
    } catch (error) {
      console.error('Error fetching user details:', error);
    }
  };

  const handleBlockUser = async (user: User, block: boolean) => {
    setActionLoading(true);
    try {
      const token = await getAuthToken();
      const response = await fetch(`/api/admin/users/${user.uid}/block`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          blocked: block,
          reason: block ? blockReason : undefined,
        }),
      });

      if (response.ok) {
        setBlockDialogOpen(false);
        setBlockReason('');
        fetchUsers();
        if (selectedUser && selectedUser.uid === user.uid) {
          fetchUserDetails(user.uid);
        }
      }
    } catch (error) {
      console.error('Error blocking user:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleGrantCoins = async (uid: string) => {
    const coins = parseInt(coinsAmount);
    if (!coins || coins <= 0) return;

    setActionLoading(true);
    try {
      const db = getFirestoreClient();
      const userRef = doc(db, 'users', uid);
      
      // Get current user data
      const userDoc = await getDoc(userRef);
      if (!userDoc.exists()) {
        console.error('User not found');
        return;
      }
      
      const currentData = userDoc.data();
      const currentCoins = currentData?.coins || 0;
      const currentTotalCoins = currentData?.totalCoins || 0;
      
      // Update coins using Firestore increment
      await updateDoc(userRef, {
        coins: increment(coins),
        totalCoins: increment(coins),
      });
      
      // Add reward record (optional - you may want to create a rewardRecord collection entry)
      // For now, we'll just update the coins
      
      setGrantCoinsDialogOpen(false);
      setCoinsAmount('');
      setGrantCoinsReason('');
      fetchUsers();
      if (selectedUser && selectedUser.uid === uid) {
        fetchUserDetails(uid);
      }
    } catch (error) {
      console.error('Error granting coins:', error);
      alert('Failed to grant coins: ' + (error as Error).message);
    } finally {
      setActionLoading(false);
    }
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>User Management</CardTitle>
          <CardDescription>
            Manage users, view details, block users, and grant coins
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Search and Filters */}
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by email, name, UID, or referral code..."
                value={searchTerm}
                onChange={(e) => {
                  setSearchTerm(e.target.value);
                  setPage(1);
                }}
                className="pl-10"
              />
            </div>
            <Select value={blockedFilter} onValueChange={(value) => {
              setBlockedFilter(value);
              setPage(1);
            }}>
              <SelectTrigger className="w-full sm:w-[180px]">
                <SelectValue placeholder="Filter by status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Users</SelectItem>
                <SelectItem value="false">Active</SelectItem>
                <SelectItem value="true">Blocked</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Users Table */}
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            </div>
          ) : users.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground">
              No users found
            </div>
          ) : (
            <>
              <div className="border rounded-lg overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-muted/50">
                      <tr>
                        <th className="px-4 py-3 text-left text-sm font-medium">User</th>
                        <th className="px-4 py-3 text-left text-sm font-medium">Coins</th>
                        <th className="px-4 py-3 text-left text-sm font-medium">Status</th>
                        <th className="px-4 py-3 text-left text-sm font-medium">Joined</th>
                        <th className="px-4 py-3 text-right text-sm font-medium">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {users.map((user) => (
                        <tr key={user.uid} className="hover:bg-muted/50">
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-3">
                              {user.photo ? (
                                <img
                                  src={user.photo}
                                  alt={user.name || 'User'}
                                  className="h-10 w-10 rounded-full"
                                />
                              ) : (
                                <div className="h-10 w-10 rounded-full bg-muted flex items-center justify-center">
                                  <User className="h-5 w-5 text-muted-foreground" />
                                </div>
                              )}
                              <div className="min-w-0">
                                <p className="text-sm font-medium truncate">
                                  {user.name || user.email || 'Unknown'}
                                </p>
                                <p className="text-xs text-muted-foreground truncate">
                                  {user.email || user.uid}
                                </p>
                                {user.userType && (
                                  <div className="mt-1 text-[11px] text-muted-foreground flex items-center gap-1">
                                    <Badge
                                      variant="outline"
                                      className="text-[10px] px-1.5 py-0 h-4"
                                    >
                                      {user.userType === 'google'
                                        ? 'Google'
                                        : user.userType === 'international'
                                        ? 'International'
                                        : 'Normal'}
                                    </Badge>
                                  </div>
                                )}
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <div className="text-sm">
                              <div className="font-medium">{user.coins.toLocaleString()}</div>
                              <div className="text-xs text-muted-foreground">
                                Total: {user.totalCoins.toLocaleString()}
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            {user.isBlocked ? (
                              <Badge variant="destructive">Blocked</Badge>
                            ) : (
                              <Badge variant="default">Active</Badge>
                            )}
                          </td>
                          <td className="px-4 py-3 text-sm text-muted-foreground">
                            {formatDate(user.joiningTimestamp)}
                          </td>
                          <td className="px-4 py-3">
                            <div className="flex items-center justify-end gap-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => fetchUserDetails(user.uid)}
                              >
                                <Eye className="h-4 w-4" />
                              </Button>
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => {
                                  setSelectedUser(user as any);
                                  setBlockDialogOpen(true);
                                }}
                              >
                                {user.isBlocked ? (
                                  <CheckCircle className="h-4 w-4 text-green-600" />
                                ) : (
                                  <Ban className="h-4 w-4 text-red-600" />
                                )}
                              </Button>
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => {
                                  setSelectedUser(user as any);
                                  setGrantCoinsDialogOpen(true);
                                }}
                              >
                                <Coins className="h-4 w-4 text-yellow-600" />
                              </Button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Pagination */}
              <div className="flex items-center justify-between">
                <div className="text-sm text-muted-foreground">
                  Page {page} of {totalPages}
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                    disabled={page === 1 || loading}
                  >
                    <ChevronLeft className="h-4 w-4" />
                    Previous
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                    disabled={page === totalPages || loading}
                  >
                    Next
                    <ChevronRight className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* User Details Dialog */}
      <Dialog open={detailsDialogOpen} onOpenChange={setDetailsDialogOpen}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>User Details</DialogTitle>
            <DialogDescription>
              Complete information about the selected user
            </DialogDescription>
          </DialogHeader>
          {selectedUser && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Name</Label>
                  <p className="text-sm">{selectedUser.name || 'N/A'}</p>
                </div>
                <div>
                  <Label>Email</Label>
                  <p className="text-sm">{selectedUser.email || 'N/A'}</p>
                </div>
                <div>
                  <Label>UID</Label>
                  <p className="text-sm font-mono text-xs">{selectedUser.uid}</p>
                </div>
                <div>
                  <Label>User Type</Label>
                  <div className="text-sm">
                    <Badge
                      variant={
                        selectedUser.userType === 'google'
                          ? 'destructive'
                          : selectedUser.userType === 'international'
                          ? 'secondary'
                          : 'default'
                      }
                    >
                      {selectedUser.userType === 'google'
                        ? 'Google'
                        : selectedUser.userType === 'international'
                        ? 'International'
                        : selectedUser.userType === 'normal'
                        ? 'Normal'
                        : 'N/A'}
                    </Badge>
                    {selectedUser.userType === 'google' && selectedUser.googleUserReason && (
                      <p className="text-xs text-muted-foreground mt-1">
                        Reason: {selectedUser.googleUserReason}
                      </p>
                    )}
                  </div>
                </div>
                <div>
                  <Label>Coins</Label>
                  <p className="text-sm font-medium">{selectedUser.coins.toLocaleString()}</p>
                </div>
                <div>
                  <Label>Total Coins</Label>
                  <p className="text-sm font-medium">{selectedUser.totalCoins.toLocaleString()}</p>
                </div>
                <div>
                  <Label>Balance</Label>
                  <p className="text-sm font-medium">{selectedUser.balance.toLocaleString()}</p>
                </div>
                <div>
                  <Label>Status</Label>
                  <div className="text-sm">
                    {selectedUser.isBlocked ? (
                      <Badge variant="destructive">Blocked</Badge>
                    ) : (
                      <Badge variant="default">Active</Badge>
                    )}
                  </div>
                </div>
                <div>
                  <Label>Referral Code</Label>
                  <p className="text-sm font-mono">{selectedUser.referralCode || 'N/A'}</p>
                </div>
                <div>
                  <Label>Referral Count</Label>
                  <p className="text-sm">{selectedUser.referralCount}</p>
                </div>
                <div>
                  <Label>Country</Label>
                  <p className="text-sm">{selectedUser.country || 'N/A'}</p>
                </div>
                <div>
                  <Label>City</Label>
                  <p className="text-sm">{selectedUser.city || 'N/A'}</p>
                </div>
                <div>
                  <Label>Joined</Label>
                  <p className="text-sm">{formatDate(selectedUser.joiningTimestamp)}</p>
                </div>
                <div>
                  <Label>Last Login</Label>
                  <p className="text-sm">{formatDate(selectedUser.lastLoginTimestamp)}</p>
                </div>
                <div>
                  <Label>Device ID</Label>
                  <p className="text-sm font-mono text-xs">{selectedUser.deviceId || 'N/A'}</p>
                </div>
                <div>
                  <Label>IP Address</Label>
                  <p className="text-sm font-mono text-xs">{selectedUser.ipAddress || 'N/A'}</p>
                </div>
                {selectedUser.installedApps && selectedUser.installedApps.length > 0 && (
                  <div className="col-span-2">
                    <Label>Installed Apps</Label>
                    <div className="flex flex-wrap gap-2 mt-1">
                      {selectedUser.installedApps.map((app, index) => (
                        <Badge key={index} variant="outline" className="text-xs">
                          {app}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
              </div>
              {selectedUser.blockedReason && (
                <div>
                  <Label>Block Reason</Label>
                  <p className="text-sm text-destructive">{selectedUser.blockedReason}</p>
                </div>
              )}
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setDetailsDialogOpen(false)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Block/Unblock Dialog */}
      <Dialog open={blockDialogOpen} onOpenChange={setBlockDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {selectedUser?.isBlocked ? 'Unblock User' : 'Block User'}
            </DialogTitle>
            <DialogDescription>
              {selectedUser?.isBlocked
                ? 'This will restore the user\'s access to the platform.'
                : 'This will prevent the user from accessing the platform.'}
            </DialogDescription>
          </DialogHeader>
          {!selectedUser?.isBlocked && (
            <div className="space-y-2">
              <Label htmlFor="reason">Reason (optional)</Label>
              <Textarea
                id="reason"
                placeholder="Enter reason for blocking..."
                value={blockReason}
                onChange={(e) => setBlockReason(e.target.value)}
              />
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setBlockDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              variant={selectedUser?.isBlocked ? 'default' : 'destructive'}
              onClick={() => selectedUser && handleBlockUser(selectedUser, !selectedUser.isBlocked)}
              disabled={actionLoading}
            >
              {actionLoading ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : selectedUser?.isBlocked ? (
                'Unblock'
              ) : (
                'Block'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Grant Coins Dialog */}
      <Dialog open={grantCoinsDialogOpen} onOpenChange={setGrantCoinsDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Grant Coins</DialogTitle>
            <DialogDescription>
              Add coins to the user's account
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="coins">Amount</Label>
              <Input
                id="coins"
                type="number"
                placeholder="Enter coin amount"
                value={coinsAmount}
                onChange={(e) => setCoinsAmount(e.target.value)}
                min="1"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="grantReason">Reason (optional)</Label>
              <Textarea
                id="grantReason"
                placeholder="Enter reason for granting coins..."
                value={grantCoinsReason}
                onChange={(e) => setGrantCoinsReason(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setGrantCoinsDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={() => selectedUser && handleGrantCoins(selectedUser.uid)}
              disabled={actionLoading || !coinsAmount || parseInt(coinsAmount) <= 0}
            >
              {actionLoading ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                'Grant Coins'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

