import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SecurityGroupsComponent } from './security-groups.component';

describe('SecurityGroupsComponent', () => {
  let component: SecurityGroupsComponent;
  let fixture: ComponentFixture<SecurityGroupsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ SecurityGroupsComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(SecurityGroupsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
